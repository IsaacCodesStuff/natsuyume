import 'package:flutter/material.dart';

class AlbumData {
  final String title;
  final String artist;
  final int year;
  final int songCount;
  final ImageProvider? coverArt;

  const AlbumData({
    required this.title,
    required this.artist,
    required this.year,
    required this.songCount,
    this.coverArt,
  });

  String get subtitle => '$artist · $year · $songCount songs';
}

class ArtistData {
  final String name;
  final int albumCount;
  final ImageProvider? photo;

  const ArtistData({required this.name, required this.albumCount, this.photo});

  String get subtitle => '$albumCount albums';
}

class CollectionTrack {
  final String path;
  final String title;
  final String artist;
  final String duration;
  final ImageProvider? albumArt;

  const CollectionTrack({
    required this.path,
    required this.title,
    required this.artist,
    required this.duration,
    this.albumArt,
  });
}

class ArtistAlbumEntry {
  final String title;
  final int year;
  final int songCount;
  final ImageProvider? coverArt;

  const ArtistAlbumEntry({
    required this.title,
    required this.year,
    required this.songCount,
    this.coverArt,
  });

  String get subtitle => '$year · $songCount songs';
}
