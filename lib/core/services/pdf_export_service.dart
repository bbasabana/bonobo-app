import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/news/domain/feed_news.dart';
import '../utils/date_formatter.dart';

/// Génère un PDF d'article avec en-tête Bonobo et contenu COMPLET.
class PdfExportService {
  Future<File> generateArticlePdf(FeedNews article) async {
    final pdf = pw.Document();

    // Texte du corps : contenu complet ou excerpt si contenu vide
    final bodyText = article.content.isNotEmpty
        ? article.content
        : article.excerpt.isNotEmpty
            ? article.excerpt
            : 'Contenu non disponible — consultez l\'article original.';

    // Diviser le texte en paragraphes
    final paragraphs = bodyText
        .split(RegExp(r'\n{2,}|\r\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (paragraphs.isEmpty) {
      paragraphs.add(bodyText.trim().isNotEmpty ? bodyText.trim() : '(Contenu non disponible)');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.green800, width: 2),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'BONOBO',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                  letterSpacing: 1.5,
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    article.sourceName,
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    DateFormatter.full(article.publishedAt),
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Via Bonobo · ${article.originalUrl}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
              pw.Text(
                'Page ${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ],
          ),
        ),
        build: (context) => [
          // Catégorie
          if (article.category != null)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.green100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                article.category!.toUpperCase(),
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.green900,
                  letterSpacing: 0.8,
                ),
              ),
            ),

          // Titre
          pw.Text(
            article.title,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              lineSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 8),

          // Meta : source + date
          pw.Row(
            children: [
              pw.Text(
                '${article.sourceName}  ·  ',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.Text(
                DateFormatter.full(article.publishedAt),
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.SizedBox(height: 14),

          // Corps : chaque paragraphe séparé
          ...paragraphs.map((para) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(
                  para,
                  style: const pw.TextStyle(
                    fontSize: 12,
                    lineSpacing: 1.8,
                    color: PdfColors.grey900,
                  ),
                  textAlign: pw.TextAlign.justify,
                ),
              )),

          pw.SizedBox(height: 20),

          // Lien source
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Source originale',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                ),
                pw.Text(
                  article.originalUrl,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue),
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
