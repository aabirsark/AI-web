import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:iconsax/iconsax.dart';
import 'package:linkpeek/linkpeek.dart';
import 'package:linkpeek/models/linkpeek.model.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:share_plus/share_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = false;
  final TextEditingController controller = TextEditingController();
  LinkPeekModel? model;
  String? text;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(
            children: [
              if (model != null)
                Expanded(
                    child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: WebInfoView(model: model, text: text),
                    ),
                  ),
                )),
              if (isLoading)
                const Expanded(
                    child: Center(
                  child: LoadingWidget(),
                )),
              // if (!isLoading) const Spacer(),
              if (!isLoading && model == null) const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  // height: 60,
                  // width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(90)),
                  child: Row(
                    children: [
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Enter your url"),
                        ),
                      )),
                      const SizedBox(
                        width: 10,
                      ),
                      GestureDetector(
                        onTap: () {
                          if (model != null) {
                            setState(() {
                              model = null;
                            });
                            return;
                          }
                          setState(() {
                            isLoading = true;
                          });
                          LinkPeek.fromUrl(controller.text).then((value) {
                            WebAIActions.extractText(value.url!).then((val) {
                              setState(() {
                                model = value;
                                text = val;
                                isLoading = false;
                              });
                            });
                          });
                        },
                        child: Container(
                          height: 45,
                          width: 110,
                          decoration: const ShapeDecoration(
                              shape: StadiumBorder(), color: Colors.white),
                          child: Center(
                            child: Text(
                              model == null ? "AI analyse" : "Reset",
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LottieBuilder.asset("assets/Animation 170946651448.json"),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.search_normal,
              size: 30,
              color: Colors.white54,
            ),
            SizedBox(
              width: 20,
            ),
            Text(
              "Searching for you...",
              style: TextStyle(fontSize: 14),
            ),
          ],
        )
      ],
    );
  }
}

class WebInfoView extends StatelessWidget {
  const WebInfoView({
    super.key,
    required this.model,
    required this.text,
  });

  final LinkPeekModel? model;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 20,
        ),
        if (model?.thumbnail != null)
          FadeIn(
            child: Container(
                clipBehavior: Clip.antiAlias,
                height: 200,
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(.1),
                    borderRadius: BorderRadius.circular(10)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    model!.thumbnail!,
                    fit: BoxFit.cover,
                  ),
                )),
          ),
        const SizedBox(
          height: 30,
        ),
        FadeIn(
          delay: const Duration(milliseconds: 500),
          child: Text(
            model?.title ?? "",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: GoogleFonts.dmSerifText().fontFamily),
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        FadeIn(
          delay: const Duration(milliseconds: 1000),
          child: Markdown(
            shrinkWrap: true,
            data: text ?? "",
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
          ),
        ),
        const SizedBox(
          height: 30,
        ),
        GestureDetector(
          onTap: () {
            Share.share((model?.title ?? "") + (text ?? ""));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20), color: Colors.white),
            child: const Center(
                child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.share,
                  color: Colors.black,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  "Share",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ],
            )),
          ),
        ),
        const SizedBox(
          height: 20,
        )
      ],
    );
  }
}

class WebAIActions {
  static Future<String> summarise_website(String description) async {
    final model = GenerativeModel(
        model: 'gemini-pro', apiKey: "AIzaSyAefk-FQIu87KCEa_TfJL1C80RGASocENs");
    final content = [
      Content.text(
          'summarise these texts: $description  ... Only give summarised text. Give in points ,bold the highlightend word, a bit long summaries ')
    ];
    final response = await model.generateContent(content);

    return response.text ?? "";
  }

  static Future<String> extractText(String url) async {
    if (url.isEmpty) {
      return "";
    }

    try {
      final response = await http.get(Uri.parse(url));

      print(response.statusCode);

      if (response.statusCode == 200) {
        return await scrapeWebsite(url);
      } else {
        return "Failed to fetch data";
      }
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String> scrapeWebsite(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = parser.parse(utf8.decode(response.bodyBytes));
        final elements = document
            .querySelectorAll('p'); // Change 'p' to the desired HTML tag
        String content = '';
        for (final element in elements) {
          content += element.text + '\n';
        }
        return await summarise_website(content);
      } else {
        return "Failed to fetch";
      }
    } catch (e) {
      return "Some erro occured";
    }
  }
}
