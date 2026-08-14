import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const ResumeAnalyzerApp());
}

// ============================================================
// APP
// ============================================================

class ResumeAnalyzerApp extends StatelessWidget {
  const ResumeAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Resume Analyzer',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// ============================================================
// STATE
// ============================================================

class _HomePageState extends State<HomePage> {
  // ==========================================================
  // GEMINI API KEY
  // ==========================================================

  

  // ==========================================================
  // FILE
  // ==========================================================

  String fileName = "No resume selected";

  Uint8List? fileBytes;

  String resumeText = "";

  // ==========================================================
  // AI RESULT
  // ==========================================================

  String analysisResult = "";

  bool isAnalyzing = false;

  int resumeScore = 0;

  String summary = "";
  String skills = "";
  String strengths = "";
  String weaknesses = "";
  String projects = "";
  String education = "";
  String jobRoles = "";
  String suggestions = "";

  // ==========================================================
  // SCORE BREAKDOWN
  // ==========================================================

  int technicalScore = 0;
  int projectScore = 0;
  int educationScore = 0;
  int experienceScore = 0;
  int atsScore = 0;
  int communicationScore = 0;

  // ==========================================================
  // PICK RESUME
  // ==========================================================

  Future<void> pickResume() async {
    final FilePickerResult? result =
        await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null) return;

    final selectedFile = result.files.single;

    setState(() {
      fileName = selectedFile.name;
      fileBytes = selectedFile.bytes;

      resumeText = "";

      analysisResult = "";

      resumeScore = 0;

      summary = "";
      skills = "";
      strengths = "";
      weaknesses = "";
      projects = "";
      education = "";
      jobRoles = "";
      suggestions = "";

      technicalScore = 0;
      projectScore = 0;
      educationScore = 0;
      experienceScore = 0;
      atsScore = 0;
      communicationScore = 0;
    });

    debugPrint("PDF selected: $fileName");
  }

  // ==========================================================
  // EXTRACT TEXT FROM PDF
  // ==========================================================

  Future<String> extractPdfText() async {
    if (fileBytes == null) {
      return "";
    }

    final PdfDocument document = PdfDocument(
      inputBytes: fileBytes!,
    );

    final String text =
        PdfTextExtractor(document).extractText();

    document.dispose();

    return text;
  }

  // ==========================================================
  // NORMALIZE TEXT
  // ==========================================================

  String normalizeText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ==========================================================
  // CHECK KEYWORDS
  // ==========================================================

  bool containsAny(
    String text,
    List<String> keywords,
  ) {
    final lower = text.toLowerCase();

    return keywords.any(
      (keyword) =>
          lower.contains(keyword.toLowerCase()),
    );
  }

  // ==========================================================
  // COUNT KEYWORDS
  // ==========================================================

  int countMatches(
    String text,
    List<String> keywords,
  ) {
    final lower = text.toLowerCase();

    int count = 0;

    for (final keyword in keywords) {
      if (lower.contains(keyword.toLowerCase())) {
        count++;
      }
    }

    return count;
  }

  // ==========================================================
  // CALCULATE TECHNICAL SKILLS
  // MAX = 20
  // ==========================================================

  int calculateTechnicalScore(String text) {
    final skills = [
      "c",
      "c++",
      "java",
      "python",
      "javascript",
      "typescript",
      "dart",
      "flutter",
      "html",
      "css",
      "sql",
      "mysql",
      "mongodb",
      "firebase",
      "react",
      "node",
      "express",
      "git",
      "github",
      "rest api",
      "api",
      "data structures",
      "algorithms",
      "dsa",
      "oops",
      "operating system",
      "computer networks",
      "dbms",
    ];

    final found = countMatches(text, skills);

    if (found >= 10) return 20;
    if (found >= 8) return 18;
    if (found >= 6) return 16;
    if (found >= 5) return 14;
    if (found >= 4) return 12;
    if (found >= 3) return 10;
    if (found >= 2) return 8;
    if (found >= 1) return 5;

    return 0;
  }

  // ==========================================================
  // CALCULATE PROJECT SCORE
  // MAX = 20
  // ==========================================================

  int calculateProjectScore(String text) {
    final lower = text.toLowerCase();

    final hasProjectSection =
        lower.contains("project") ||
        lower.contains("projects");

    final projectTechnologyCount =
        countMatches(
      text,
      [
        "java",
        "python",
        "c",
        "c++",
        "flutter",
        "dart",
        "javascript",
        "html",
        "css",
        "sql",
        "firebase",
        "mongodb",
        "react",
        "node",
        "api",
      ],
    );

    final hasProjectDescription =
        containsAny(
      text,
      [
        "developed",
        "developing",
        "created",
        "built",
        "implemented",
        "designed",
        "application",
        "website",
        "system",
        "project",
      ],
    );

    if (!hasProjectSection) {
      return 0;
    }

    int score = 8;

    if (projectTechnologyCount >= 2) {
      score += 4;
    }

    if (projectTechnologyCount >= 4) {
      score += 3;
    }

    if (hasProjectDescription) {
      score += 3;
    }

    return math.min(score, 20);
  }

  // ==========================================================
  // CALCULATE EDUCATION SCORE
  // MAX = 15
  // ==========================================================

  int calculateEducationScore(String text) {
    int score = 0;

    final lower = text.toLowerCase();

    final hasDegree =
        containsAny(
      text,
      [
        "b.tech",
        "btech",
        "bachelor",
        "b.sc",
        "bca",
        "mca",
        "m.tech",
        "computer science",
        "information technology",
      ],
    );

    final hasCollege =
        containsAny(
      text,
      [
        "college",
        "university",
        "institute",
        "institution",
      ],
    );

    final hasSchool =
        containsAny(
      text,
      [
        "class 10",
        "class x",
        "10th",
        "class 12",
        "class xii",
        "12th",
        "higher secondary",
      ],
    );

    final hasPercentage =
        containsAny(
      text,
      [
        "%",
        "percentage",
        "cgpa",
        "sgpa",
      ],
    );

    if (hasDegree) {
      score += 7;
    }

    if (hasCollege) {
      score += 3;
    }

    if (hasSchool) {
      score += 2;
    }

    if (hasPercentage) {
      score += 2;
    }

    // Year / batch information
    if (RegExp(r'20\d{2}').hasMatch(lower)) {
      score += 1;
    }

    return math.min(score, 15);
  }

  // ==========================================================
  // EXPERIENCE & ACHIEVEMENTS
  // MAX = 15
  // ==========================================================

  int calculateExperienceScore(String text) {
    int score = 0;

    final hasExperience =
        containsAny(
      text,
      [
        "experience",
        "internship",
        "intern",
        "work experience",
        "professional experience",
      ],
    );

    final hasAchievements =
        containsAny(
      text,
      [
        "achievement",
        "achievements",
        "certification",
        "certifications",
        "certificate",
        "hackathon",
        "competition",
        "award",
        "nptel",
        "workshop",
        "bootcamp",
      ],
    );

    final hasLeadership =
        containsAny(
      text,
      [
        "leadership",
        "team leader",
        "coordinator",
        "volunteer",
        "organizer",
      ],
    );

    if (hasExperience) {
      score += 7;
    }

    if (hasAchievements) {
      score += 5;
    }

    if (hasLeadership) {
      score += 3;
    }

    return math.min(score, 15);
  }

  // ==========================================================
  // ATS & RESUME QUALITY
  // MAX = 15
  // ==========================================================

  int calculateAtsScore(String text) {
    int score = 0;

    final lower = text.toLowerCase();

    // Contact information
    if (RegExp(
      r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
      caseSensitive: false,
    ).hasMatch(text)) {
      score += 2;
    }

    // Phone number
    if (RegExp(
      r'\b\d{10}\b',
    ).hasMatch(text.replaceAll(' ', ''))) {
      score += 2;
    }

    // Important resume sections
    final sections = [
      "education",
      "skills",
      "projects",
      "experience",
      "summary",
    ];

    int sectionCount = 0;

    for (final section in sections) {
      if (lower.contains(section)) {
        sectionCount++;
      }
    }

    if (sectionCount >= 5) {
      score += 5;
    } else if (sectionCount >= 4) {
      score += 4;
    } else if (sectionCount >= 3) {
      score += 3;
    } else if (sectionCount >= 2) {
      score += 2;
    }

    // GitHub / LinkedIn
    if (containsAny(
      text,
      [
        "github",
        "linkedin",
      ],
    )) {
      score += 2;
    }

    // Resume keywords
    if (containsAny(
      text,
      [
        "skills",
        "programming",
        "developer",
        "software",
        "technical",
      ],
    )) {
      score += 2;
    }

    return math.min(score, 15);
  }

  // ==========================================================
  // COMMUNICATION & PRESENTATION
  // MAX = 15
  // ==========================================================

  int calculateCommunicationScore(String text) {
    int score = 0;

    final lower = text.toLowerCase();

    // Summary / objective
    if (containsAny(
      text,
      [
        "summary",
        "objective",
        "profile",
      ],
    )) {
      score += 3;
    }

    // Languages
    if (containsAny(
      text,
      [
        "english",
        "hindi",
        "language",
        "languages",
      ],
    )) {
      score += 2;
    }

    // Soft skills
    final softSkills = [
      "communication",
      "teamwork",
      "leadership",
      "problem solving",
      "adaptability",
      "quick learner",
      "time management",
      "collaboration",
    ];

    final softSkillCount =
        countMatches(text, softSkills);

    if (softSkillCount >= 4) {
      score += 5;
    } else if (softSkillCount >= 2) {
      score += 3;
    } else if (softSkillCount >= 1) {
      score += 2;
    }

    // Action-oriented words
    final actionWords = [
      "developed",
      "created",
      "implemented",
      "designed",
      "built",
      "managed",
      "analyzed",
      "improved",
    ];

    final actionCount =
        countMatches(text, actionWords);

    if (actionCount >= 4) {
      score += 3;
    } else if (actionCount >= 2) {
      score += 2;
    } else if (actionCount >= 1) {
      score += 1;
    }

    // Avoid extremely short extracted resumes
    if (lower.length > 500) {
      score += 2;
    }

    return math.min(score, 15);
  }

  // ==========================================================
  // CALCULATE COMPLETE SCORE
  // ==========================================================

  void calculatePlacementScore(String text) {
    technicalScore =
        calculateTechnicalScore(text);

    projectScore =
        calculateProjectScore(text);

    educationScore =
        calculateEducationScore(text);

    experienceScore =
        calculateExperienceScore(text);

    atsScore =
        calculateAtsScore(text);

    communicationScore =
        calculateCommunicationScore(text);

    resumeScore =
        technicalScore +
        projectScore +
        educationScore +
        experienceScore +
        atsScore +
        communicationScore;

    resumeScore =
        math.min(resumeScore, 100);
  }

  // ==========================================================
  // GEMINI ANALYSIS
  // ==========================================================

  Future<String> getGeminiAnalysis(
  String text,
) async {
  final response = await http.post(
    Uri.parse('http://localhost:3000/analyze'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'resumeText': text,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Backend error: ${response.statusCode}',
    );
  }

  final data = jsonDecode(response.body);

  return data['analysis'] ??
      'No analysis was returned.';
}

  // ==========================================================
  // PARSE AI RESPONSE
  // ==========================================================

  void parseAnalysis(String result) {
    analysisResult = result;

    summary =
        extractSection(result, "SUMMARY");

    skills =
        extractSection(result, "SKILLS FOUND");

    strengths =
        extractSection(result, "STRENGTHS");

    weaknesses =
        extractSection(
      result,
      "MISSING OR WEAK SKILLS",
    );

    projects =
        extractSection(result, "PROJECTS");

    education =
        extractSection(result, "EDUCATION");

    jobRoles =
        extractSection(
      result,
      "SUITABLE JOB ROLES",
    );

    suggestions =
        extractSection(
      result,
      "IMPROVEMENT SUGGESTIONS",
    );
  }

  // ==========================================================
  // EXTRACT SECTION
  // ==========================================================

  String extractSection(
    String text,
    String section,
  ) {
    final normalized =
        text.replaceAll('\r\n', '\n');

    final sectionRegex = RegExp(
      r'(?:^|\n)\s*(?:#+\s*)?(?:\*{0,2})' +
          RegExp.escape(section) +
          r'(?:\*{0,2})\s*:?',
      caseSensitive: false,
    );

    final match =
        sectionRegex.firstMatch(normalized);

    if (match == null) {
      return "";
    }

    final start = match.end;

    const nextSections = [
      "SUMMARY",
      "SKILLS FOUND",
      "STRENGTHS",
      "MISSING OR WEAK SKILLS",
      "PROJECTS",
      "EDUCATION",
      "SUITABLE JOB ROLES",
      "IMPROVEMENT SUGGESTIONS",
    ];

    int end = normalized.length;

    for (final next in nextSections) {
      if (next.toUpperCase() ==
          section.toUpperCase()) {
        continue;
      }

      final regex = RegExp(
        r'(?:^|\n)\s*(?:#+\s*)?(?:\*{0,2})' +
            RegExp.escape(next) +
            r'(?:\*{0,2})\s*:?',
        caseSensitive: false,
      );

      final nextMatch =
          regex.firstMatch(
        normalized.substring(start),
      );

      if (nextMatch != null) {
        final position =
            start + nextMatch.start;

        if (position < end) {
          end = position;
        }
      }
    }

    String value =
        normalized.substring(start, end).trim();

    value = value.replaceAll(
      RegExp(r'\*\*'),
      '',
    );

    value = value.replaceAll(
      RegExp(r'###'),
      '',
    );

    return value.trim();
  }

  // ==========================================================
  // START ANALYSIS
  // ==========================================================

  Future<void> startAnalysis() async {
    if (fileBytes == null) {
      setState(() {
        analysisResult =
            "Please upload a resume first.";
      });

      return;
    }

    

    setState(() {
      isAnalyzing = true;
      analysisResult = "";
    });

    try {
      // Extract resume
      final extracted =
          await extractPdfText();

      if (extracted.trim().isEmpty) {
        setState(() {
          isAnalyzing = false;
          analysisResult =
              "Could not extract text from this PDF.";
        });

        return;
      }

      resumeText =
          normalizeText(extracted);

      debugPrint(
        "Resume text extracted successfully.",
      );

      // ======================================================
      // IMPORTANT:
      // SCORE IS CALCULATED DIRECTLY FROM RESUME TEXT
      // ======================================================

      calculatePlacementScore(
        resumeText,
      );

      debugPrint(
        "Technical: $technicalScore / 20",
      );

      debugPrint(
        "Projects: $projectScore / 20",
      );

      debugPrint(
        "Education: $educationScore / 15",
      );

      debugPrint(
        "Experience: $experienceScore / 15",
      );

      debugPrint(
        "ATS: $atsScore / 15",
      );

      debugPrint(
        "Communication: $communicationScore / 15",
      );

      debugPrint(
        "TOTAL: $resumeScore / 100",
      );

      // ======================================================
      // GEMINI QUALITATIVE ANALYSIS
      // ======================================================

      final result =
          await getGeminiAnalysis(
        resumeText,
      );

      debugPrint("AI ANALYSIS:");
      debugPrint(result);

      parseAnalysis(result);

      setState(() {
        isAnalyzing = false;
      });
    } catch (e) {
      debugPrint("ERROR: $e");

      setState(() {
        isAnalyzing = false;

        analysisResult =
            "Something went wrong:\n\n$e";
      });
    }
  }

  // ==========================================================
  // SCORE COLOR
  // ==========================================================

  Color getScoreColor() {
    if (resumeScore >= 80) {
      return Colors.green;
    }

    if (resumeScore >= 60) {
      return Colors.orange;
    }

    return Colors.red;
  }

  // ==========================================================
  // READINESS TEXT
  // ==========================================================

  String getReadinessText() {
    if (resumeScore >= 80) {
      return "Highly Ready for Entry-Level Jobs";
    }

    if (resumeScore >= 70) {
      return "Good Preparation for Entry-Level Jobs";
    }

    if (resumeScore >= 60) {
      return "Moderately Ready for Entry-Level Jobs";
    }

    if (resumeScore >= 40) {
      return "Needs Improvement for Entry-Level Jobs";
    }

    return "Early Stage – Needs Significant Improvement";
  }

  // ==========================================================
  // SCORE BREAKDOWN CARD
  // ==========================================================

  Widget scoreBreakdownCard() {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 20),
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: Colors.blue,
              ),
              const SizedBox(width: 10),
              const Text(
                "Score Breakdown",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          scoreRow(
            "Technical Skills",
            technicalScore,
            20,
          ),

          scoreRow(
            "Projects",
            projectScore,
            20,
          ),

          scoreRow(
            "Education",
            educationScore,
            15,
          ),

          scoreRow(
            "Experience & Achievements",
            experienceScore,
            15,
          ),

          scoreRow(
            "ATS & Resume Quality",
            atsScore,
            15,
          ),

          scoreRow(
            "Communication & Presentation",
            communicationScore,
            15,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SCORE ROW
  // ==========================================================

  Widget scoreRow(
    String title,
    int score,
    int maxScore,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
              Text(
                "$score / $maxScore",
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child:
                LinearProgressIndicator(
              minHeight: 7,
              value:
                  maxScore == 0
                      ? 0
                      : score / maxScore,
              backgroundColor:
                  Colors.grey.shade200,
              valueColor:
                  AlwaysStoppedAnimation<
                      Color>(
                score >= maxScore * .7
                    ? Colors.green
                    : score >= maxScore * .4
                        ? Colors.orange
                        : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MAIN SCORE CARD
  // ==========================================================

  Widget scoreCard() {
    if (resumeScore == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 20),
      padding:
          const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Placement Readiness",
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment:
                  Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child:
                      CircularProgressIndicator(
                    value:
                        resumeScore / 100,
                    strokeWidth: 13,
                    backgroundColor:
                        Colors.grey.shade200,
                    valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                      getScoreColor(),
                    ),
                  ),
                ),

                Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      "$resumeScore%",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            getScoreColor(),
                      ),
                    ),

                    const Text(
                      "Score",
                      style: TextStyle(
                        color:
                            Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(
            getReadinessText(),
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
              color:
                  getScoreColor(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RESULT SECTION CARD
  // ==========================================================

  Widget sectionCard(
    String title,
    IconData icon,
    String content,
  ) {
    if (content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 16),
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.blue,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            content,
            style:
                const TextStyle(
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CLEAN PDF TEXT
  // ==========================================================

  String cleanForPdf(String text) {
    return text
        .replaceAll('###', '')
        .replaceAll('**', '')
        .trim();
  }

  // ==========================================================
  // PDF SECTION
  // ==========================================================

  pw.Widget pdfSection(
    String title,
    String content,
  ) {
    if (content.trim().isEmpty) {
      return pw.SizedBox();
    }

    return pw.Container(
      margin:
          const pw.EdgeInsets.only(
        bottom: 18,
      ),
      child: pw.Column(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 17,
              fontWeight:
                  pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 7),

          pw.Text(
            cleanForPdf(content),
            style:
                const pw.TextStyle(
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DOWNLOAD ANALYSIS PDF
  // ==========================================================

  Future<void> downloadAnalysisPdf() async {
    if (analysisResult.trim().isEmpty) {
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        margin:
            const pw.EdgeInsets.all(35),
        build: (context) {
          return [
            pw.Text(
              "AI Resume Analysis",
              style: pw.TextStyle(
                fontSize: 26,
                fontWeight:
                    pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 8),

            pw.Text(
              "Resume: $fileName",
              style:
                  const pw.TextStyle(
                fontSize: 12,
              ),
            ),

            pw.Divider(),

            pw.SizedBox(height: 15),

            pw.Text(
              "Placement Readiness Score: "
              "$resumeScore / 100",
              style: pw.TextStyle(
                fontSize: 21,
                fontWeight:
                    pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 8),

            pw.Text(
              getReadinessText(),
              style:
                  const pw.TextStyle(
                fontSize: 12,
              ),
            ),

            pw.SizedBox(height: 20),

            pw.Text(
              "Score Breakdown",
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight:
                    pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Text(
              "Technical Skills: "
              "$technicalScore / 20",
            ),

            pw.Text(
              "Projects: "
              "$projectScore / 20",
            ),

            pw.Text(
              "Education: "
              "$educationScore / 15",
            ),

            pw.Text(
              "Experience & Achievements: "
              "$experienceScore / 15",
            ),

            pw.Text(
              "ATS & Resume Quality: "
              "$atsScore / 15",
            ),

            pw.Text(
              "Communication & Presentation: "
              "$communicationScore / 15",
            ),

            pw.SizedBox(height: 25),

            pdfSection(
              "Professional Summary",
              summary,
            ),

            pdfSection(
              "Skills Found",
              skills,
            ),

            pdfSection(
              "Strengths",
              strengths,
            ),

            pdfSection(
              "Missing / Weak Skills",
              weaknesses,
            ),

            pdfSection(
              "Project Analysis",
              projects,
            ),

            pdfSection(
              "Education",
              education,
            ),

            pdfSection(
              "Suitable Job Roles",
              jobRoles,
            ),

            pdfSection(
              "Improvement Suggestions",
              suggestions,
            ),

            pw.SizedBox(height: 20),

            pw.Divider(),

            pw.Text(
              "Generated by AI Resume Analyzer",
              style:
                  const pw.TextStyle(
                fontSize: 10,
              ),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: "Resume_Analysis.pdf",
    );
  }

  // ==========================================================
  // UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Colors.white,
        title: const Text(
          "AI Resume Analyzer",
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 900,
            ),
            child: Column(
              children: [
                const SizedBox(height: 15),

                // =================================================
                // HEADER
                // =================================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(25),
                  decoration:
                      BoxDecoration(
                    gradient:
                        const LinearGradient(
                      colors: [
                        Color(0xFF2563EB),
                        Color(0xFF4F46E5),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 55,
                        color:
                            Colors.white,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      const Text(
                        "AI Resume Analyzer",
                        style:
                            TextStyle(
                          fontSize: 28,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Colors.white,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        "Analyze your resume with AI",
                        style:
                            TextStyle(
                          color: Colors.white
                              .withOpacity(
                            0.9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // =================================================
                // UPLOAD CARD
                // =================================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(20),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf,
                        size: 50,
                        color: Colors.red,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        fileName,
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton
                                .icon(
                          onPressed:
                              isAnalyzing
                                  ? null
                                  : pickResume,
                          icon:
                              const Icon(
                            Icons.upload_file,
                          ),
                          label:
                              const Text(
                            "Choose PDF Resume",
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton
                                .icon(
                          onPressed:
                              isAnalyzing
                                  ? null
                                  : startAnalysis,
                          icon:
                              isAnalyzing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                        color:
                                            Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.analytics,
                                    ),
                          label: Text(
                            isAnalyzing
                                ? "Analyzing..."
                                : "Analyze Resume",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                // =================================================
                // LOADING
                // =================================================

                if (isAnalyzing)
                  const Padding(
                    padding:
                        EdgeInsets.all(25),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),

                        SizedBox(
                          height: 15,
                        ),

                        Text(
                          "AI is analyzing your resume...",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // =================================================
                // RESULTS
                // =================================================

                if (!isAnalyzing &&
                    analysisResult.isNotEmpty)
                  Column(
                    children: [
                      scoreCard(),

                      scoreBreakdownCard(),

                      sectionCard(
                        "Professional Summary",
                        Icons.person_outline,
                        summary,
                      ),

                      sectionCard(
                        "Skills Found",
                        Icons.code,
                        skills,
                      ),

                      sectionCard(
                        "Strengths",
                        Icons
                            .thumb_up_alt_outlined,
                        strengths,
                      ),

                      sectionCard(
                        "Missing / Weak Skills",
                        Icons
                            .warning_amber_outlined,
                        weaknesses,
                      ),

                      sectionCard(
                        "Project Analysis",
                        Icons.folder_outlined,
                        projects,
                      ),

                      sectionCard(
                        "Education",
                        Icons.school_outlined,
                        education,
                      ),

                      sectionCard(
                        "Suitable Job Roles",
                        Icons.work_outline,
                        jobRoles,
                      ),

                      sectionCard(
                        "Improvement Suggestions",
                        Icons
                            .lightbulb_outline,
                        suggestions,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      // =================================================
                      // DOWNLOAD PDF
                      // =================================================

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton
                                .icon(
                          onPressed:
                              downloadAnalysisPdf,
                          icon:
                              const Icon(
                            Icons.picture_as_pdf,
                          ),
                          label:
                              const Text(
                            "Download Analysis as PDF",
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}