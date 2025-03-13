import 'package:flutter/material.dart';
import 'package:krewe_iq/components/custom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9D00CC), Color(0xFF4A148C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(maxWidth: 976),
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Contact",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                      "Have questions, feedback, trivia, or just want to say hi? I'd love to hear from you! Feel free to reach out at "),
                  // Vertical stacking: first the text, then the image.
                  InkWell(
                    onTap: () async {
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: 'kreweiqnola@gmail.com',
                      );
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Could not launch email client')),
                        );
                      }
                    },
                    child: const Text(
                      "kreweiqnola@gmail.com",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text("251-454-1107"),
                  const SizedBox(height: 20),
                  const Divider(
                    color: Color(0xFF4A148C),
                    thickness: 1,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Refund & Dispute Policy",
                    style: (TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Text(
                      "At Krewe IQ, we strive to provide high-quality Mardi Gras trivia content and a fun, engaging experience. Because our digital products are instantly accessible upon purchase, all sales are final, and we do not offer refunds.\n\n"
                      "However, if you experience technical issues or believe there was an error with your purchase, please contact us at kreweiq@gmail.com within 7 days of purchase. We will review your case and determine if a resolution, such as credit toward a future purchase or a refund, is warranted.\n\n"
                      "If you have concerns about unauthorized transactions or billing errors, please reach out to us before disputing a charge with your payment provider. We will work with you to resolve any issues as quickly as possible.\n\n"),
                  Text(
                    "Cancellation Policy",
                    style: (TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Text(
                      "Currently, Krewe IQ does not offer subscription-based services, so cancellations do not apply to our platform. Once a trivia pack or Krewe Selector access is purchased, it remains available to you as per our service terms.\n\n"
                      "If we introduce subscription services in the future, we will update this policy accordingly. For any questions, please contact kreweiq@gmail.com.\n\n"),
                  Text(
                    "Legal & Export Restrictions",
                    style: (TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Text(
                      "Krewe IQ is a digital trivia platform designed for users within jurisdictions where digital content purchases are legally permitted. By purchasing and using our service, you confirm that you are in compliance with your local laws regarding digital purchases.\n\n"
                      "Our content is intended for personal, non-commercial use. Redistribution, resale, or unauthorized sharing of our trivia questions, Krewe Selector quiz, or any other digital assets is strictly prohibited.\n\n"
                      "We do not knowingly provide services to individuals in regions subject to U.S. export restrictions or economic sanctions. If you are located in a restricted territory, you may not be able to access or purchase our content.\n\n"
                      "For more information on compliance or legal inquiries, please contact kreweiq@gmail.com."),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
