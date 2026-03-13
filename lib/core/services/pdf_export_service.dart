import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/news/domain/feed_news.dart';
import '../utils/date_formatter.dart';

/// Génère un PDF d'article avec en-tête Bonobo et contenu COMPLET.
class PdfExportService {
  Future<File> generateArticlePdf(FeedNews article) async {
    final pdf = pw.Document();

    // 1. Charger la police supportant les caractères spéciaux (Roboto)
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // 2. Charger le logo Bonobo depuis les assets
    Uint8List? logoData;
    try {
      final ByteData bytes = await rootBundle.load('assets/images/logo_icon_white.png');
      logoData = bytes.buffer.asUint8List();
    } catch (_) {}

    // 3. Charger l'image de l'article si elle existe
    Uint8List? articleImageData;
    if (article.imageUrl != null && article.imageUrl!.isNotEmpty) {
      try {
        final response = await Dio().get<List<int>>(
          article.imageUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null) {
          articleImageData = Uint8List.fromList(response.data!);
        }
      } catch (_) {}
    }

    // 4. Préparer le texte (Contenu complet prioritaire)
    final bodyText = article.content.isNotEmpty
        ? article.content
        : article.excerpt.isNotEmpty
            ? article.excerpt
            : 'Contenu non disponible — consultez l\'article original.';

    // Nettoyage sommaire des doubles retours à la ligne
    final paragraphs = bodyText
        .split(RegExp(r'\n{2,}|\r\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        header: (context) => pw.Container(
          height: 50,
          margin: const pw.EdgeInsets.only(bottom: 20),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF01732C), width: 1.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Logo + Texte Bonobo
              pw.Row(
                children: [
                  if (logoData != null)
                    pw.Image(pw.MemoryImage(logoData), width: 30, height: 30),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    'BONOBO',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF01732C),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    article.sourceName,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    DateFormatter.full(article.publishedAt),
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 20),
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Document généré par Bonobo — L\'actualité congolaise à portée de main.',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic),
              ),
              pw.Text(
                'Page ${context.pageNumber} / ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ],
          ),
        ),
        build: (context) => [
          // Catégorie
          if (article.category != null)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE8F5E9),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                article.category!.split(',').first.trim().toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColor.fromInt(0xFF2E7D32),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

          // Titre
          pw.Text(
            article.title,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
              lineSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 20),

          // Image principale de l'article
          if (articleImageData != null)
            pw.Column(
              children: [
                pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Image(
                    pw.MemoryImage(articleImageData),
                    fit: pw.BoxFit.cover,
                    width: double.infinity,
                    height: 250,
                  ),
                ),
                pw.SizedBox(height: 20),
              ],
            ),

          // Corps de l'article
          ...paragraphs.map((para) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 14),
                child: pw.Text(
                  para,
                  style: pw.TextStyle(
                    fontSize: 12,
                    lineSpacing: 1.6,
                    color: PdfColors.black,
                  ),
                  textAlign: pw.TextAlign.justify,
                ),
              )),

          pw.SizedBox(height: 30),
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.SizedBox(height: 15),

          // Section Source et Signature
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF9F9F9),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SOURCE DE L\'ARTICLE',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  article.sourceName,
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF01732C)),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  article.originalUrl,
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.blue700, decoration: pw.TextDecoration.underline),
                ),
                pw.SizedBox(height: 15),
                pw.Text(
                  'Bonobo est un agrégateur de nouvelles. Cet article appartient à sa source originale mentionnée ci-dessus.',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final dir = Directory.systemTemp;
    final safeName = article.id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final file = File('${dir.path}/bonobo_$safeName.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
