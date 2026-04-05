import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) throw new Error("Not authenticated");

    const { data: onboarding } = await supabase
      .from("onboarding_responses")
      .select("*")
      .eq("user_id", user.id)
      .single();

    if (!onboarding) throw new Error("No onboarding data found");

    const prompt = `You are a certified personal trainer. Create a weekly workout plan based on:

- Goal: ${onboarding.goal}
- Days per week: ${onboarding.days_per_week}
- Session length: ${onboarding.session_length}
- Equipment: ${onboarding.equipment}
- Injury/pain area: ${onboarding.injury_area}${onboarding.injury_note ? ` (${onboarding.injury_note})` : ""}

Rules:
- Only use exercises possible with the listed equipment
- Avoid exercises that stress the injured area (if any)
- Fit each session within the time limit
- Return ONLY valid JSON, no markdown fences, no explanation

Return this exact JSON structure:
{
  "summary": "short label like '3-day dumbbell plan'",
  "description": "one sentence explaining why this plan fits the user",
  "days": [
    {
      "dayNumber": 1,
      "name": "session name",
      "durationMinutes": number,
      "exercises": [
        { "name": "exercise name", "sets": number, "reps": number, "rest": "rest time string" }
      ]
    }
  ]
}`;

    const openaiRes = await fetch(
      "https://api.openai.com/v1/chat/completions",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-4o-mini",
          messages: [{ role: "user", content: prompt }],
          temperature: 0.7,
        }),
      }
    );

    const openaiData = await openaiRes.json();
    const raw = openaiData.choices[0].message.content.trim();
    const planJson = JSON.parse(raw);

    await supabase.from("user_plans").insert({
      user_id: user.id,
      plan_json: planJson,
    });

    return new Response(JSON.stringify(planJson), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
