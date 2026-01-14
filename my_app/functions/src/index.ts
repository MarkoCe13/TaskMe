import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";

const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

export const generateDailyPlan = onCall(
  { secrets: [OPENAI_API_KEY] },
  async (request) => {
    try {

      if (!request.auth) {
        throw new HttpsError("unauthenticated", "You must be signed in.");
      }

      const data = request.data ?? {};
      const tasks = Array.isArray(data.tasks) ? data.tasks : [];
      const dateLabel = typeof data.dateLabel === "string" ? data.dateLabel : "today";


      const taskText = tasks
        .map((t: any, i: number) => {
          const title = String(t.title ?? "").trim();
          const desc = String(t.description ?? "").trim();
          const status = String(t.status ?? "").trim();
          const deadline = String(t.deadline ?? "").trim();
          return `${i + 1}. ${title}${desc ? ` — ${desc}` : ""}${status ? ` [${status}]` : ""}${deadline ? ` (deadline: ${deadline})` : ""}`;
        })
        .join("\n");

      const prompt = `
        You are creating a fully planned day schedule for ${dateLabel}.
        
        INPUT:
        - The list below contains ONLY tasks that are due TODAY, and each task includes a deadline time.
        
        HARD RULES:
        - Output MUST be valid JSON only (no markdown, no extra text).
        - Build a schedule from 09:00 to 21:00.
        - Every entry MUST have an exact start and end time in 24h format: "HH:mm - HH:mm".
        - Use ALL provided tasks exactly once (do not repeat tasks).
        - Do NOT invent new tasks.
        - Do NOT schedule any task after its deadline time (it must finish before or at the deadline).
        - You MAY add non-task blocks to fill the day, such as: "Break", "Lunch", "Dinner", "Free time", "Buffer".
        - Keep the day realistic (include short breaks between blocks).
        - If there are no tasks, still return a full-day schedule with breaks/free time.
        
        OUTPUT JSON FORMAT (exact keys):
        {
          "summary": "Your plan for today",
          "plan": [
            { "time": "09:00 - 09:30", "title": "Break", "details": "Coffee / prep" },
            { "time": "09:30 - 10:15", "title": "Task title", "details": "Short detail" }
          ],
          "tips": [
            "If the walk is missed: Fit it in during a break."
          ]
        }
        
        Tasks (today only, each includes a deadline time):
        ${taskText || "(no tasks provided)"}
        `.trim();


      const apiKey = OPENAI_API_KEY.value();
      if (!apiKey) {
        throw new HttpsError("failed-precondition", "Missing OPENAI_API_KEY secret.");
      }

      const resp = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-4o-mini",
          temperature: 0.6,
          messages: [
            { role: "system", content: "You are a helpful planner." },
            { role: "user", content: prompt },
          ],
        }),
      });

      if (!resp.ok) {
        const errText = await resp.text();
        logger.error("OpenAI error", { status: resp.status, errText });
        throw new HttpsError("internal", `OpenAI failed (${resp.status}): ${errText}`);
      }

      const json: any = await resp.json();

      const content =
        json?.choices?.[0]?.message?.content?.trim() ?? "";

      let parsed: any;
      try {
        parsed = JSON.parse(content);
      } catch (e) {
        logger.error("AI did not return valid JSON", { content });
        throw new HttpsError(
          "internal",
          "AI returned invalid JSON."
        );
      }

      return { plan: parsed };


    } catch (e: any) {
      logger.error("generateDailyPlan failed", e);
      if (e instanceof HttpsError) throw e;
      throw new HttpsError("internal", "Something went wrong.");
    }
  }
);
