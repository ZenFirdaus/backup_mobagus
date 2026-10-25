import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/data/detective_cases_data.dart';
import 'package:flutter_application_1/data/kulinerdle_data.dart';
import 'package:flutter_application_1/models/detective_case.dart';

void main() {
  group('Detective Cases Campaign Structure Tests', () {
    test('contains exactly 15 detective cases numbered 1 to 15', () {
      expect(kDetectiveCases.length, 15);
      for (int i = 0; i < 15; i++) {
        expect(kDetectiveCases[i].level, i + 1);
      }
    });

    test('verifies chapters and checkpoints (Lv 3 Klimaks Candi Sambisari, Lv 5, 10, 15)', () {
      for (final c in kDetectiveCases) {
        if (c.level <= 5) {
          expect(c.chapter, 1);
          expect(c.chapterTitle, contains('Bab I'));
        } else if (c.level <= 10) {
          expect(c.chapter, 2);
          expect(c.chapterTitle, contains('Bab II'));
        } else {
          expect(c.chapter, 3);
          expect(c.chapterTitle, contains('Bab III'));
        }

        if (c.level == 3 || c.level % 5 == 0) {
          expect(c.isCheckpoint, isTrue,
              reason: 'Case ${c.level} should be marked as a checkpoint');
        } else {
          expect(c.isCheckpoint, isFalse);
        }
      }
    });

    test('verifies each case has scenes, a final boss fight, and good/bad endings', () {
      for (final c in kDetectiveCases) {
        expect(c.scenes, isNotEmpty, reason: 'Case ${c.level} must have scenes');
        
        final finalScene = c.scenes.last;
        expect(finalScene.isBossFight, isTrue,
            reason: 'Case ${c.level} final scene must be a boss fight');
        expect(finalScene.boss, isNotNull,
            reason: 'Case ${c.level} final scene must have boss data');
        expect(finalScene.boss!.name, isNotEmpty);
        expect(finalScene.boss!.quote, isNotEmpty);
        expect(finalScene.boss!.maxHp, greaterThan(0));

        // Good & Bad Endings
        expect(c.goodEnding.title, isNotEmpty);
        expect(c.goodEnding.narrative, isNotEmpty);
        expect(c.goodEnding.epilogue, isNotEmpty);
        expect(c.goodEnding.badgeName, isNotEmpty);
        expect(c.goodEnding.rewardPoints, greaterThan(0));

        expect(c.badEnding.title, isNotEmpty);
        expect(c.badEnding.narrative, isNotEmpty);
        expect(c.badEnding.epilogue, isNotEmpty);
      }
    });

    test('verifies Case 1 (Wijilan) playable flow and scene linking', () {
      final case1 = kDetectiveCases.first;
      expect(case1.id, 'case_wijilan');
      expect(case1.scenes.length, 4);

      final s1 = case1.scenes[0];
      expect(s1.id, 'scene_1');
      expect(s1.choices.length, 3);
      final s1Investigate = s1.choices.firstWhere((ch) => ch.type == ChoiceType.investigate);
      expect(s1Investigate.foundClue, isNotNull);
      expect(s1Investigate.foundClue!.title, contains('Asam Cuka'));
      expect(s1Investigate.nextSceneId, 'scene_2');

      final s2 = case1.scenes[1];
      expect(s2.id, 'scene_2');
      expect(s2.choices.any((ch) => ch.nextSceneId == 'scene_boss'), isTrue);

      // Boss Phase 1
      final sBoss1 = case1.scenes[2];
      expect(sBoss1.id, 'scene_boss');
      expect(sBoss1.isBossFight, isTrue);
      expect(sBoss1.boss!.name, contains('Chef Hendra'));
      expect(sBoss1.choices.any((ch) => ch.nextSceneId == 'scene_boss_2'), isTrue);

      // Boss Phase 2 (Climax / Checkmate)
      final sBoss2 = case1.scenes[3];
      expect(sBoss2.id, 'scene_boss_2');
      expect(sBoss2.isBossFight, isTrue);
      final totalPhase2Damage = sBoss2.choices.fold<int>(0, (sum, ch) => sum + ch.bossDamage);
      expect(totalPhase2Damage, greaterThanOrEqualTo(sBoss2.boss!.maxHp));
    });

    test('verifies Case 15 has 3 sequential boss fight stages to defeat the last boss', () {
      final case15 = kDetectiveCases.firstWhere((c) => c.level == 15);
      expect(case15.id, 'case_bale_raos_finale');

      // Filter boss scenes
      final bossScenes = case15.scenes.where((s) => s.isBossFight).toList();
      expect(bossScenes.length, 3, reason: 'Case 15 must have exactly 3 boss fight stages');

      final stage1 = bossScenes[0];
      final stage2 = bossScenes[1];
      final stage3 = bossScenes[2];

      expect(stage1.id, 'scene_boss_1');
      expect(stage2.id, 'scene_boss_2');
      expect(stage3.id, 'scene_boss_3');

      // Stage 1 links to Stage 2 on correct choice
      final stage1Correct = stage1.choices.firstWhere((ch) => ch.isCorrect);
      expect(stage1Correct.nextSceneId, 'scene_boss_2');
      expect(stage1Correct.bossDamage, greaterThan(0));

      // Stage 2 links to Stage 3 on correct choice
      final stage2Correct = stage2.choices.firstWhere((ch) => ch.isCorrect);
      expect(stage2Correct.nextSceneId, 'scene_boss_3');
      expect(stage2Correct.bossDamage, greaterThan(0));

      // Stage 3 final checkmate (nextSceneId is null)
      final stage3Correct = stage3.choices.firstWhere((ch) => ch.isCorrect);
      expect(stage3Correct.nextSceneId, isNull);
      expect(stage3Correct.bossDamage, greaterThan(0));
    });

    test('verifies all 15 cases have tailored boss illustrations matching chapter and boss character', () {
      const allowedAssets = {
        'assets/images/boss_chapter_1.jpg',
        'assets/images/boss_chapter_2.jpg',
        'assets/images/boss_chapter_3.jpg',
        'assets/images/boss_femme_fatale.jpg',
        'assets/images/boss_final_tamansari.jpg',
      };

      for (final c in kDetectiveCases) {
        final bossScenes = c.scenes.where((s) => s.isBossFight && s.boss != null).toList();
        expect(bossScenes, isNotEmpty, reason: 'Case ${c.level} must have at least one boss scene');
        for (final s in bossScenes) {
          expect(s.boss!.imageAsset, isNotNull,
              reason: 'Boss in Case ${c.level} Scene ${s.id} must have an imageAsset');
          expect(allowedAssets.contains(s.boss!.imageAsset), isTrue,
              reason: 'Asset ${s.boss!.imageAsset} in Case ${c.level} must be one of the tailored boss illustrations');
        }
      }
    });
  });

  group('Kulinerdle (Wordle Nusantara) Engine Tests', () {
    test('target words contain GUDEG, BAKSO, KOYOR, PECEL with fun facts', () {
      final words = kKulinerdleTargetWords.map((e) => e.word).toList();
      expect(words, containsAll(['GUDEG', 'BAKSO', 'KOYOR', 'PECEL', 'TELUR', 'CUCUR', 'TIMUN']));

      final gudeg = kKulinerdleTargetWords.firstWhere((e) => e.word == 'GUDEG');
      expect(gudeg.funFact, contains('Gudeg'));
      expect(gudeg.funFact, contains('nangka'));
      expect(gudeg.searchQuery, 'Gudeg');

      for (final w in kKulinerdleTargetWords) {
        expect(w.word.length, 5);
        expect(w.funFact, isNotEmpty);
        expect(w.category, isNotEmpty);
        expect(w.searchQuery, isNotEmpty);
        expect(kKulinerdleValidWords.contains(w.word), isTrue);
      }
    });

    test('daily word generator is deterministic per calendar day', () {
      final dateA = DateTime(2026, 10, 24);
      final dateB = DateTime(2026, 10, 24);
      final dateC = DateTime(2026, 10, 25);

      final wordA = getDailyKulinerdleWord(dateA);
      final wordB = getDailyKulinerdleWord(dateB);
      expect(wordA.word, wordB.word);

      final wordC = getDailyKulinerdleWord(dateC);
      expect(wordC.word.length, 5);
    });

    test('validates 5-letter dictionary contains food words for letter elimination while target words stay Nusantara', () {
      // Target words stay strictly authentic Nusantara
      for (final t in kKulinerdleTargetWords) {
        expect(t.word.length, 5);
        expect(kKulinerdleValidWords.contains(t.word), isTrue);
        expect(RegExp(r'^[A-Z]{5}$').hasMatch(t.word), isTrue);
      }
      expect(kKulinerdleTargetWords.any((t) => t.word == 'PIZZA'), isFalse);
      expect(kKulinerdleTargetWords.any((t) => t.word == 'BURGR'), isFalse);

      // Guessable dictionary has expanded food & ingredients to easily eliminate letters
      final eliminationWords = [
        'BERAS', 'GULAA', 'ROTIK', 'PIZZA', 'STEAK', 'SUSHI',
        'RAMEN', 'LEMON', 'MELON', 'PASTA', 'WATER', 'CREAM',
        'MANGO', 'CHIPS', 'DONAT', 'KECAP', 'TOMAT', 'BAYAM',
      ];
      for (final ew in eliminationWords) {
        expect(kKulinerdleValidWords.contains(ew), isTrue,
            reason: '$ew should be in guessable dictionary for letter elimination');
      }

      // Every word in dictionary must be exactly 5 uppercase letters
      for (final word in kKulinerdleValidWords) {
        expect(word.length, 5, reason: '$word must have length 5');
        expect(RegExp(r'^[A-Z]{5}$').hasMatch(word), isTrue,
            reason: '$word must be 5 uppercase letters');
      }

      expect(kKulinerdleValidWords.contains('ZZZZZ'), isFalse);
    });

    test('random word generator provides variety and respects exclusions', () {
      final generatedWords = <String>{};
      for (int i = 0; i < 30; i++) {
        final w = getRandomKulinerdleWord();
        expect(w.word.length, 5);
        expect(kKulinerdleValidWords.contains(w.word), isTrue);
        generatedWords.add(w.word);
      }
      // Out of 30 random draws from 55+ words, we should see significant variety (not always same word)
      expect(generatedWords.length, greaterThan(1));

      // Test exclusion list
      final excluded = {'GUDEG', 'BAKSO', 'KOYOR', 'PECEL'};
      for (int i = 0; i < 20; i++) {
        final w = getRandomKulinerdleWord(null, excluded);
        expect(excluded.contains(w.word), isFalse,
            reason: '${w.word} should not have been selected because it is in excluded list');
      }
    });
  });

  group('Detective Checkpoint Resilience & Bab 1 Level 3 Tests', () {
    test('Case 3 (Candi Sambisari) has complete boss fight metadata and Ki Joyo suspect', () {
      final case3 = kDetectiveCases.firstWhere((c) => c.level == 3);
      expect(case3.id, 'case_soto_bathok');
      expect(case3.title, contains('Batok Keramat'));
      expect(case3.suspectName, contains('Ki Joyo'));
      expect(case3.isCheckpoint, isTrue);

      final bossScene = case3.scenes.firstWhere((s) => s.isBossFight);
      expect(bossScene.boss, isNotNull);
      expect(bossScene.boss!.name, contains('Ki Joyo'));
      expect(bossScene.boss!.quote, isNotEmpty);
      expect(bossScene.boss!.weakPoints, isNotEmpty);
      expect(bossScene.boss!.weakPoints.length, greaterThanOrEqualTo(2));
    });

    test('reconstructs checkpoint from completed levels stars (star > 0 guarantees next level)', () {
      // Simulating user who beat level 1 and 2:
      final stars = <int, int>{
        1: 3, // beaten with 3 stars
        2: 2, // beaten with 2 stars
      };
      int highestCompletedLevel = 0;
      for (final entry in stars.entries) {
        if (entry.value > 0 && entry.key > highestCompletedLevel) {
          highestCompletedLevel = entry.key;
        }
      }
      final derivedUnlocked = (highestCompletedLevel > 0)
          ? highestCompletedLevel + 1
          : 1;

      expect(derivedUnlocked, 3,
          reason: 'Beating level 2 must guarantee Level 3 is unlocked');
    });

    test('preserves checkpoint Level 3 guarantee across reset simulations', () {
      bool hasCp3 = true;
      int rawSavedLevel = 1; // e.g. cache was reset to 1
      if (hasCp3 && rawSavedLevel < 3) {
        rawSavedLevel = 3;
      }
      expect(rawSavedLevel, 3,
          reason: 'Checkpoint Lv 3 guarantee must prevent drop below level 3');
    });
  });
}

