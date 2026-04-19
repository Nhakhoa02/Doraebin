import 'package:flutter/material.dart';

class WordItem {
  final String text;
  final String imageUrl;
  final String? lottieUrl;

  const WordItem({
    required this.text,
    required this.imageUrl,
    this.lottieUrl,
  });
}

class Lesson {
  final String id;
  final String title;
  final String emoji;
  final MaterialColor color;
  final List<WordItem> words;

  const Lesson({
    required this.id,
    required this.title,
    required this.emoji,
    required this.color,
    required this.words,
  });
}

/// Initial curated lessons for the kid.
final List<Lesson> curatedLessons = [
  const Lesson(
    id: 'l1',
    title: 'Động Vật',
    emoji: '🐶',
    color: Colors.orange,
    words: [
      WordItem(
        text: 'Con mèo',
        imageUrl: 'https://img.freepik.com/free-vector/cute-cat-sitting-cartoon-vector-icon-illustration-animal-nature-icon-concept-isolated-premium-vector-flat-cartoon-style_138676-4148.jpg',
        lottieUrl: 'https://assets5.lottiefiles.com/packages/lf20_syAs6Y.json',
      ),
      WordItem(
        text: 'Con chó',
        imageUrl: 'https://img.freepik.com/free-vector/cute-dog-sitting-cartoon-vector-icon-illustration-animal-nature-icon-concept-isolated-premium-vector-flat-cartoon-style_138676-4140.jpg',
        lottieUrl: 'https://assets9.lottiefiles.com/packages/lf20_96bzne6w.json',
      ),
      WordItem(
        text: 'Con gà',
        imageUrl: 'https://img.freepik.com/free-vector/cute-chicken-cartoon-vector-icon-illustration-animal-nature-icon-concept-isolated-premium-vector-flat-cartoon-style_138676-4158.jpg',
      ),
      WordItem(
        text: 'Con hổ',
        imageUrl: 'https://img.freepik.com/free-vector/cute-tiger-cartoon-vector-icon-illustration-animal-nature-icon-concept-isolated-premium-vector-flat-cartoon-style_138676-4151.jpg',
      ),
    ],
  ),
  const Lesson(
    id: 'l2',
    title: 'Trái Cây',
    emoji: '🍎',
    color: Colors.red,
    words: [
      WordItem(
        text: 'Quả táo',
        imageUrl: 'https://img.freepik.com/free-vector/red-apple-fruit-cartoon-vector-icon-illustration-food-nature-icon-concept-isolated-premium-vector-flat-cartoon-style_138676-4157.jpg',
      ),
      WordItem(
        text: 'Quả chuối',
        imageUrl: 'https://img.freepik.com/free-vector/banana-fruit-cartoon-vector-icon-illustration-food-nature-icon-concept-isolated-premium-vector-flat-cartoon-style_138676-4156.jpg',
      ),
      WordItem(
        text: 'Quả cam',
        imageUrl: 'https://img.freepik.com/free-vector/orange-fruit-cartoon-vector-icon-illustration-food-nature-icon-concept-isolated-premium-vector-flat-cartoon-style_138676-4154.jpg',
      ),
    ],
  ),
  const Lesson(
    id: 'l3',
    title: 'Màu Sắc',
    emoji: '🌈',
    color: Colors.blue,
    words: [
      WordItem(
        text: 'Màu đỏ',
        imageUrl: 'https://img.freepik.com/free-vector/abstract-red-vibrant-square_1308-4159.jpg',
      ),
      WordItem(
        text: 'Màu xanh',
        imageUrl: 'https://img.freepik.com/free-vector/abstract-blue-vibrant-square_1308-4160.jpg',
      ),
      WordItem(
        text: 'Màu vàng',
        imageUrl: 'https://img.freepik.com/free-vector/abstract-yellow-vibrant-square_1308-4161.jpg',
      ),
    ],
  ),
];
