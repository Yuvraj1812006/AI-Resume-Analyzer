const express = require("express");
const cors = require("cors");
require("dotenv").config();

const { GoogleGenAI } = require("@google/genai");

const app = express();

app.use(cors());
app.use(express.json({ limit: "5mb" }));

const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

app.get("/", (req, res) => {
  res.json({
    message: "AI Resume Analyzer Backend is running",
  });
});

app.post("/analyze", async (req, res) => {
  try {
    const { resumeText } = req.body;

    if (!resumeText || resumeText.trim() === "") {
      return res.status(400).json({
        error: "Resume text is required",
      });
    }

    const prompt = `
You are an expert technical recruiter evaluating a college student's resume for entry-level software and IT placements.

IMPORTANT:
Only use information actually present in the resume.
Do not invent projects, experience, certifications, skills, marks, or achievements.

Return EXACTLY these sections:

SUMMARY:
Give a concise professional summary.

SKILLS FOUND:
List the technical and soft skills actually found.

STRENGTHS:
List the strongest parts of the resume.

MISSING OR WEAK SKILLS:
List realistic areas that should be improved.

PROJECTS:
Describe and evaluate the projects actually present in the resume.

EDUCATION:
Summarize the education actually present.

SUITABLE JOB ROLES:
Give 4 to 6 suitable entry-level roles based on the actual skills.

IMPROVEMENT SUGGESTIONS:
Give 5 practical placement-oriented suggestions.

Do not give a resume score.
The application calculates the score separately.

RESUME:
${resumeText}
`;

    const response = await ai.models.generateContent({
      model: "gemini-3.6-flash",
      contents: prompt,
    });

    const result = response.text || "No analysis was returned.";

    res.json({
      analysis: result,
    });
  } catch (error) {
    console.error("Gemini error:", error);

    res.status(500).json({
      error: "Failed to analyze resume",
    });
  }
});

const PORT = 3000;

app.listen(PORT, () => {
  console.log(`Backend running on http://localhost:${PORT}`);
});