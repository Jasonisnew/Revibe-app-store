import "@supabase/functions-js/edge-runtime.d.ts";

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
    const {
      movementName,
      formScore,
      repsCompleted,
      totalReps,
      duration,
    } = await req.json();

    const prompt = `You are a concise fitness coach. The user just finished a workout session.

Exercise: ${movementName}
Form score: ${formScore}/100
Reps completed: ${repsCompleted} out of ${totalReps} target
Duration: ${duration}

Give exactly ONE short, personalized coaching takeaway (max 2 sentences). Be encouraging but specific. Focus on what they can improve next time based on the form score and rep completion. Do not use bullet points. Do not repeat the stats back.`;

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
          temperature: 0.8,
          max_tokens: 120,
        }),
      }
    );

    const data = await openaiRes.json();
    const tip = data.choices[0].message.content.trim();

    return new Response(JSON.stringify({ tip }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
