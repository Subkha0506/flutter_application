import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BeritaPage extends StatefulWidget {
  final Map article;

  const BeritaPage({Key? key, required this.article}) : super(key: key);

  @override
  State<BeritaPage> createState() => _BeritaPageState();
}

class _BeritaPageState extends State<BeritaPage> {
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    final prefs = await SharedPreferences.getInstance();
    final likedArticles = prefs.getStringList('liked_articles') ?? [];

    setState(() {
      isLiked = likedArticles.any((articleJson) {
        final article = jsonDecode(articleJson);
        return article['title'] == widget.article['title'];
      });
    });
  }

  Future<void> _toggleLike() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> likedArticles = prefs.getStringList('liked_articles') ?? [];

    if (isLiked) {
      likedArticles.removeWhere((articleJson) {
        final article = jsonDecode(articleJson);
        return article['title'] == widget.article['title'];
      });
    } else {
      likedArticles.add(jsonEncode(widget.article));
    }

    await prefs.setStringList('liked_articles', likedArticles);

    setState(() {
      isLiked = !isLiked;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isLiked ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Tidak bisa membuka $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Detail Berita",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : Colors.grey,
              size: 28,
            ),
            onPressed: _toggleLike,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.article["image"] ??
                      "https://via.placeholder.com/400x200",
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              Text(
                widget.article["title"] ?? "No Title",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(Icons.source, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    widget.article["source"]?["name"] ?? "Unknown",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    widget.article["publishedAt"]?.toString().substring(
                          0,
                          10,
                        ) ??
                        "",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (widget.article["description"] != null)
                Text(
                  widget.article["description"],
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (widget.article["url"] != null) {
                      _launchUrl(widget.article["url"]);
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text("Baca Artikel Lengkap"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
