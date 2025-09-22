import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'Like.dart';
import 'profil.dart';
import 'berita.dart';

class beranda extends StatefulWidget {
  const beranda({Key? key}) : super(key: key);

  @override
  State<beranda> createState() => _berandaState();
}

class _berandaState extends State<beranda> {
  List articles = [];
  List filteredArticles = [];
  bool isLoading = true;

  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchArticles();
  }

  Future<void> fetchArticles() async {
    try {
      final url = Uri.parse(
        "https://gnews.io/api/v4/search?q=indonesia&lang=id&country=id&max=10&apikey=288881761b7851043da400a133de1b7c",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          articles = (data["articles"] as List?) ?? [];
          filteredArticles = articles;
          isLoading = false;
        });
      } else {
        debugPrint("Error: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  void _filterArticles(String query) {
    final hasil = articles.where((article) {
      final title = (article["title"] ?? "").toLowerCase();
      return title.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredArticles = hasil;
    });
  }

  // ignore: unused_element
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Tidak bisa membuka $url");
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LikePage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilPage()),
      );
    }
  }

  void _navigateToDetail(Map article) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BeritaPage(article: article)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Cari berita...",
                  border: InputBorder.none,
                ),
                onChanged: _filterArticles,
              )
            : const Text(
                "Berita Terkini",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                if (_showSearch) {
                  _searchController.clear();
                  filteredArticles = articles;
                }
                _showSearch = !_showSearch;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : filteredArticles.isEmpty
            ? const Center(child: Text("Tidak ada berita"))
            : ListView.builder(
                itemCount: filteredArticles.length,
                itemBuilder: (context, index) {
                  final article = filteredArticles[index];
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
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    article["source"]?["name"] ?? "Unknown",
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
                                  const SizedBox(height: 6),
                                  const Text(
                                    "Ketuk untuk baca detail",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: "Suka",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profil",
          ),
        ],
      ),
    );
  }
}
