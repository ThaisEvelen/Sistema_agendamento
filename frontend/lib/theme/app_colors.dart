import 'package:flutter/material.dart';

// Paleta principal — roxo + índigo
const Color kPurple = Color(0xFF7C3AED);
const Color kIndigo = Color(0xFF4F46E5);
const Color kPurpleDark = Color(0xFF6D28D9);
const Color kPurpleLight = Color(0xFFEDE9FE);

const List<Color> kGradient = [kPurple, kIndigo];

// Gradiente diagonal padrão
const LinearGradient kPrimaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: kGradient,
);
