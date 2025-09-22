import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'beranda.dart';
import 'profil.dart';
import 'berita.dart';

class LikePage extends StatefulWidget {
  const LikePage({Key? key}) : super(key: key);

  @override
  State<LikePage> createState() => _LikePageState();
}

class _LikePageState extends State<LikePage> {
  List<Map> likedArticles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLikedArticles();
  }

  Future<void> _loadLikedArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final likedArticlesList = prefs.getStringList('liked_articles') ?? [];

    setState(() {
      likedArticles = likedArticlesList.map((articleJson) {
        return Map<String, dynamic>.from(jsonDecode(articleJson));
      }).toList();
      isLoading = false;
    });
  }

  Future<void> _removeFromLiked(Map article) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> likedArticlesList =
        prefs.getStringList('liked_articles') ?? [];

    likedArticlesList.removeWhere((articleJson) {
      final storedArticle = jsonDecode(articleJson);
      return storedArticle['title'] == article['title'];
    });

    await prefs.setStringList('liked_articles', likedArticlesList);

    setState(() {
      likedArticles.removeWhere((item) => item['title'] == article['title']);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Berita dihapus dari favorit'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showRemoveDialog(Map article) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus dari Favorit?'),
          content: Text(
            'Apakah Anda yakin ingin menghapus "${article['title']}" dari daftar favorit?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeFromLiked(article);
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToDetail(Map article) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BeritaPage(article: article)),
    ).then((_) { 
      _loadLikedArticles();
    });
  }

  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const beranda()),
      );
    } else if (index == 1) { 
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Berita Favorit",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadLikedArticles,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : likedArticles.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Belum ada berita favorit",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Klik ikon hati pada berita untuk menambahkan ke favorit",
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${likedArticles.length} Berita Favorit",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: likedArticles.length,
                      itemBuilder: (context, index) {
                        final article = likedArticles[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _navigateToDetail(article),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      article["image"] ??
                                          "https://via.placeholder.com/150",
                                      width: 120,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 120,
                                              height: 100,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          article["title"] ?? "No Title",
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          article["source"]?["name"] ??
                                              "Unknown",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          article["publishedAt"]
                                                  ?.toString()
                                                  .substring(0, 10) ??
                                              "",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _showRemoveDialog(article),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Suka"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}
