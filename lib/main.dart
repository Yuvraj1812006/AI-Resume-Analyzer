import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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
        scaffoldBackgroundColor: const Color(0xFFF6F8FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
        ),
        fontFamily: 'Arial',
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

class _HomePageState extends State<HomePage> {
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
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
      );

      if (result.isEmpty) return;

      final selectedFile = result.first;

      final xFile = selectedFile.xFile;
      final Uint8List bytes = await xFile.readAsBytes();

      if (bytes.isEmpty) {
        setState(() {
          fileName = "Could not read selected PDF";
          fileBytes = null;
        });
        return;
      }

      setState(() {
        fileName = selectedFile.name;
        fileBytes = bytes;

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
      debugPrint("PDF bytes loaded: ${bytes.length}");
    } catch (e) {
      debugPrint("PDF selection error: $e");

      setState(() {
        fileName = "Error reading PDF";
        fileBytes = null;
        analysisResult = "Could not read the PDF:\n$e";
      });
    }
  }

  // ==========================================================
  // EXTRACT PDF TEXT
  // ==========================================================

  Future<String> extractPdfText() async {
    if (fileBytes == null) return "";

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
  // KEYWORD HELPERS
  // ==========================================================

  bool containsAny(
    String text,
    List<String> keywords,
  ) {
    final lower = text.toLowerCase();

    return keywords.any(
      (keyword) => lower.contains(keyword.toLowerCase()),
    );
  }

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
  // TECHNICAL SCORE
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

  // ============================================================
  // PROJECT SCORE
  // MAX = 20
  // ============================================================

  int calculateProjectScore(String text) {
    final lower = text.toLowerCase();

    final hasProjectSection =
        lower.contains("project") ||
        lower.contains("projects");

    final projectTechnologyCount = countMatches(
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

    final hasProjectDescription = containsAny(
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

    if (!hasProjectSection) return 0;

    int score = 8;

    if (projectTechnologyCount >= 2) score += 4;
    if (projectTechnologyCount >= 4) score += 3;
    if (hasProjectDescription) score += 3;

    return math.min(score, 20);
  }

  // ============================================================
  // EDUCATION SCORE
  // MAX = 15
  // ============================================================

  int calculateEducationScore(String text) {
    int score = 0;

    final lower = text.toLowerCase();

    final hasDegree = containsAny(
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

    final hasCollege = containsAny(
      text,
      [
        "college",
        "university",
        "institute",
        "institution",
      ],
    );

    final hasSchool = containsAny(
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

    final hasPercentage = containsAny(
      text,
      [
        "%",
        "percentage",
        "cgpa",
        "sgpa",
      ],
    );

    if (hasDegree) score += 7;
    if (hasCollege) score += 3;
    if (hasSchool) score += 2;
    if (hasPercentage) score += 2;

    if (RegExp(r'20\d{2}').hasMatch(lower)) {
      score += 1;
    }

    return math.min(score, 15);
  }

  // ============================================================
  // EXPERIENCE SCORE
  // MAX = 15
  // ============================================================

  int calculateExperienceScore(String text) {
    int score = 0;

    final hasExperience = containsAny(
      text,
      [
        "experience",
        "internship",
        "intern",
        "work experience",
        "professional experience",
      ],
    );

    final hasAchievements = containsAny(
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

    final hasLeadership = containsAny(
      text,
      [
        "leadership",
        "team leader",
        "coordinator",
        "volunteer",
        "organizer",
      ],
    );

    if (hasExperience) score += 7;
    if (hasAchievements) score += 5;
    if (hasLeadership) score += 3;

    return math.min(score, 15);
  }

  // ============================================================
  // ATS SCORE
  // MAX = 15
  // ============================================================

  int calculateAtsScore(String text) {
    int score = 0;

    final lower = text.toLowerCase();

    if (RegExp(
      r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
      caseSensitive: false,
    ).hasMatch(text)) {
      score += 2;
    }

    if (RegExp(r'\b\d{10}\b')
        .hasMatch(text.replaceAll(' ', ''))) {
      score += 2;
    }

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

    if (containsAny(text, ["github", "linkedin"])) {
      score += 2;
    }

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

  // ============================================================
  // COMMUNICATION SCORE
  // MAX = 15
  // ============================================================

  int calculateCommunicationScore(String text) {
    int score = 0;

    final lower = text.toLowerCase();

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

    if (lower.length > 500) score += 2;

    return math.min(score, 15);
  }

  // ============================================================
  // COMPLETE SCORE
  // ============================================================

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

    resumeScore = math.min(resumeScore, 100);
  }

  // ============================================================
  // BACKEND / GEMINI
  // ============================================================

  Future<String> getGeminiAnalysis(String text) async {
    final response = await http.post(
      Uri.parse(
        'https://ai-resume-analyzer-1-e03n.onrender.com/analyze',
      ),
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

  // ============================================================
  // PARSE AI RESPONSE
  // ============================================================

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

  // ============================================================
  // EXTRACT SECTION
  // ============================================================

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

    if (match == null) return "";

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

  // ============================================================
  // START ANALYSIS
  // ============================================================

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

      calculatePlacementScore(resumeText);

      final result =
          await getGeminiAnalysis(
        resumeText,
      );

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

  // ============================================================
  // SCORE HELPERS
  // ============================================================

  Color getScoreColor() {
    if (resumeScore >= 80) {
      return Colors.green;
    }

    if (resumeScore >= 60) {
      return Colors.orange;
    }

    return Colors.red;
  }

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

  // ============================================================
  // GRADIENT
  // ============================================================

  LinearGradient primaryGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF2563EB),
        Color(0xFF4F46E5),
      ],
    );
  }

  // ============================================================
  // UPLOAD CARD
  // ============================================================

  Widget uploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEEE),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              size: 42,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "Upload your resume",
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            "Upload a PDF resume and get an AI-powered analysis",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      isAnalyzing ? null : pickResume,
                  icon: const Icon(
                    Icons.upload_file_rounded,
                  ),
                  label: const Text(
                    "Choose PDF",
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      isAnalyzing
                          ? null
                          : startAnalysis,
                  icon: isAnalyzing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.auto_awesome,
                        ),
                  label: Text(
                    isAnalyzing
                        ? "Analyzing..."
                        : "Analyze Resume",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    minimumSize:
                        const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SCORE CARD
  // ============================================================

  Widget scoreCard() {
    if (resumeScore == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: primaryGradient(),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB)
                .withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Placement Readiness",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Your resume performance at a glance",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 28),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 170,
                height: 170,
                child: CircularProgressIndicator(
                  value: resumeScore / 100,
                  strokeWidth: 14,
                  backgroundColor:
                      Colors.white.withOpacity(0.18),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    "$resumeScore",
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "/ 100",
                    style: TextStyle(
                      color:
                          Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              getReadinessText(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SCORE BREAKDOWN
  // ============================================================

  Widget scoreBreakdownCard() {
    return dashboardCard(
      title: "Score Breakdown",
      subtitle:
          "How your resume performs across key areas",
      icon: Icons.bar_chart_rounded,
      child: Column(
        children: [
          scoreRow(
            "Technical Skills",
            technicalScore,
            20,
            Icons.code_rounded,
          ),
          scoreRow(
            "Projects",
            projectScore,
            20,
            Icons.folder_copy_outlined,
          ),
          scoreRow(
            "Education",
            educationScore,
            15,
            Icons.school_outlined,
          ),
          scoreRow(
            "Experience & Achievements",
            experienceScore,
            15,
            Icons.workspace_premium_outlined,
          ),
          scoreRow(
            "ATS & Resume Quality",
            atsScore,
            15,
            Icons.fact_check_outlined,
          ),
          scoreRow(
            "Communication",
            communicationScore,
            15,
            Icons.forum_outlined,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SCORE ROW
  // ============================================================

  Widget scoreRow(
    String title,
    int score,
    int maxScore,
    IconData icon,
  ) {
    final percentage =
        maxScore == 0 ? 0.0 : score / maxScore;

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFEFF6FF),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color:
                      const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                "$score / $maxScore",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: percentage,
              backgroundColor:
                  const Color(0xFFE5E7EB),
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                percentage >= .7
                    ? Colors.green
                    : percentage >= .4
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DASHBOARD CARD
  // ============================================================

  Widget dashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFEFF6FF),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color:
                      const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // ============================================================
  // RESULT SECTION
  // ============================================================

  Widget resultSection(
    String title,
    String content,
    IconData icon,
    Color accent,
  ) {
    if (content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: accent,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 14.5,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PDF CLEAN
  // ============================================================

  String cleanForPdf(String text) {
    return text
        .replaceAll('###', '')
        .replaceAll('**', '')
        .trim();
  }

  // ============================================================
  // PDF SECTION
  // ============================================================

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

  // ============================================================
  // DOWNLOAD PDF
  // ============================================================

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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: primaryGradient(),
                borderRadius:
                    BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            const Text(
              "AI Resume Analyzer",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 950,
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // =================================================
                // HERO
                // =================================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: primaryGradient(),
                    borderRadius:
                        BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFF2563EB)
                                .withOpacity(0.20),
                        blurRadius: 25,
                        offset:
                            const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration:
                            BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.14),
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 17),
                      const Text(
                        "Analyze Your Resume with AI",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        "Get actionable insights, placement readiness scores "
                        "and personalized career recommendations.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(0.85),
                          fontSize: 14.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // =================================================
                // UPLOAD
                // =================================================

                uploadCard(),

                const SizedBox(height: 25),

                // =================================================
                // LOADING
                // =================================================

                if (isAnalyzing)
                  Container(
                    width: double.infinity,
                    margin:
                        const EdgeInsets.only(
                      bottom: 22,
                    ),
                    padding:
                        const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        const Text(
                          "AI is analyzing your resume...",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Extracting skills, projects and placement insights",
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                // =================================================
                // RESULTS
                // =================================================

                if (!isAnalyzing &&
                    analysisResult.isNotEmpty) ...[
                  scoreCard(),
                  scoreBreakdownCard(),

                  resultSection(
                    "Professional Summary",
                    summary,
                    Icons.person_outline_rounded,
                    Colors.blue,
                  ),

                  resultSection(
                    "Skills Found",
                    skills,
                    Icons.code_rounded,
                    Colors.indigo,
                  ),

                  resultSection(
                    "Strengths",
                    strengths,
                    Icons.thumb_up_alt_outlined,
                    Colors.green,
                  ),

                  resultSection(
                    "Missing / Weak Skills",
                    weaknesses,
                    Icons.warning_amber_rounded,
                    Colors.orange,
                  ),

                  resultSection(
                    "Project Analysis",
                    projects,
                    Icons.folder_outlined,
                    Colors.deepPurple,
                  ),

                  resultSection(
                    "Education",
                    education,
                    Icons.school_outlined,
                    Colors.teal,
                  ),

                  resultSection(
                    "Suitable Job Roles",
                    jobRoles,
                    Icons.work_outline_rounded,
                    Colors.blue,
                  ),

                  resultSection(
                    "Improvement Suggestions",
                    suggestions,
                    Icons.lightbulb_outline_rounded,
                    Colors.amber.shade800,
                  ),

                  const SizedBox(height: 5),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          downloadAnalysisPdf,
                      icon: const Icon(
                        Icons.picture_as_pdf_rounded,
                      ),
                      label: const Text(
                        "Download Analysis as PDF",
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xFF111827,
                        ),
                        foregroundColor:
                            Colors.white,
                        minimumSize:
                            const Size.fromHeight(
                          54,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}