const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { defineSecret } = require("firebase-functions/params");

// Store API key as Firebase secret (set via: firebase functions:secrets:set GEMINI_API_KEY)
const geminiApiKey = defineSecret("GEMINI_API_KEY");

const GEMINI_PROMPT = `Analyze this dog pedigree document image. Extract ALL dogs visible in the pedigree tree as JSON.

IMPORTANT RULES:
- The MAIN DOG (Hovedhund) is the dog this pedigree belongs to. Its name is usually at the top, often after a label like "Name:", "Navn:", "Nimi:", "Namn:", or in the title.
- The SIRE (Far/Father) is marked with labels like "Sire:", "Far:", "Father:", "Fader:", "Isä:"
- The DAM (Mor/Mother) is marked with labels like "Dam:", "Mor:", "Mother:", "Moder:", "Emä:"
- Most pedigrees show 3 generations: parents, grandparents, and great-grandparents
- Great-grandparents are the outermost/rightmost column in the pedigree tree
- Registration numbers look like "NO12345/2020", "FIN12345/20", "S12345/2020", etc.
- Dates can be dd.mm.yyyy, dd/mm/yyyy, or yyyy-mm-dd format
- Keep dates in the format you find them
- If you cannot read a field clearly, set it to null
- Names of dogs are typically multi-word, often including kennel names like "Kennel's Champion Name"
- Gender must be exactly "Male" or "Female" or null

Return ONLY valid JSON in this exact format (no markdown, no code blocks):
{
  "main_dog": {
    "name": "string or null",
    "registration_number": "string or null",
    "breed": "string or null",
    "birth_date": "string or null",
    "color": "string or null",
    "gender": "Male or Female or null"
  },
  "sire": {
    "name": "string or null",
    "registration_number": "string or null",
    "breed": "string or null",
    "birth_date": "string or null"
  },
  "dam": {
    "name": "string or null",
    "registration_number": "string or null",
    "breed": "string or null",
    "birth_date": "string or null"
  },
  "paternal_grandfather": {"name": "string or null", "registration_number": "string or null"},
  "paternal_grandmother": {"name": "string or null", "registration_number": "string or null"},
  "maternal_grandfather": {"name": "string or null", "registration_number": "string or null"},
  "maternal_grandmother": {"name": "string or null", "registration_number": "string or null"},
  "paternal_gf_father": {"name": "string or null", "registration_number": "string or null"},
  "paternal_gf_mother": {"name": "string or null", "registration_number": "string or null"},
  "paternal_gm_father": {"name": "string or null", "registration_number": "string or null"},
  "paternal_gm_mother": {"name": "string or null", "registration_number": "string or null"},
  "maternal_gf_father": {"name": "string or null", "registration_number": "string or null"},
  "maternal_gf_mother": {"name": "string or null", "registration_number": "string or null"},
  "maternal_gm_father": {"name": "string or null", "registration_number": "string or null"},
  "maternal_gm_mother": {"name": "string or null", "registration_number": "string or null"}
}`;

exports.scanPedigree = onCall(
  {
    secrets: [geminiApiKey],
    memory: "512MiB",
    timeoutSeconds: 60,
    maxInstances: 20,
    // Allow up to 5MB image uploads
    enforceAppCheck: false,
  },
  async (request) => {
    // Require authentication
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Du må være logget inn for å skanne.");
    }

    const { imageBase64 } = request.data;
    if (!imageBase64 || typeof imageBase64 !== "string") {
      throw new HttpsError("invalid-argument", "Mangler bildedata.");
    }

    // Validate size (roughly 5MB in base64)
    if (imageBase64.length > 7_000_000) {
      throw new HttpsError("invalid-argument", "Bildet er for stort. Maks 5MB.");
    }

    const apiKey = geminiApiKey.value();
    if (!apiKey) {
      throw new HttpsError("failed-precondition", "Gemini API-nøkkel er ikke konfigurert på serveren.");
    }

    try {
      const genAI = new GoogleGenerativeAI(apiKey);
      const model = genAI.getGenerativeModel({
        model: "gemini-2.0-flash",
        generationConfig: {
          temperature: 0.1,
          maxOutputTokens: 4096,
        },
      });

      const imagePart = {
        inlineData: {
          data: imageBase64,
          mimeType: "image/jpeg",
        },
      };

      const result = await model.generateContent([GEMINI_PROMPT, imagePart]);
      const response = result.response;
      const text = response.text();

      if (!text) {
        throw new HttpsError("internal", "Gemini returnerte tomt svar.");
      }

      // Clean markdown code blocks if present
      let jsonStr = text.trim();
      if (jsonStr.startsWith("```")) {
        jsonStr = jsonStr.replace(/^```(json)?\s*/, "").replace(/\s*```$/, "");
      }

      // Validate it's valid JSON
      const parsed = JSON.parse(jsonStr);
      return { success: true, data: parsed, rawText: text };
    } catch (error) {
      console.error("Gemini API error:", error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", `Feil ved analyse av stamtavle: ${error.message}`);
    }
  }
);
