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

    test('verifies chapters and checkpoints (Lv 5, 10, 15)', () {
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

        if (c.level % 5 == 0) {
          expect(c.isCheckpoint, isTrue);
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
  });

  group('Kulinerdle (Wordle Nusantara) Engine Tests', () {
    test('target words contain GUDEG, BAKSO, KOYOR, PECEL with fun facts', () {
      final words = kKulinerdleTargetWords.map((e) => e.word).toList();
      expect(words, containsAll(['GUDEG', 'BAKSO', 'KOYOR', 'PECEL']));

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

    test('validates 5-letter dictionary contains food words', () {
      expect(kKulinerdleValidWords.contains('GUDEG'), isTrue);
      expect(kKulinerdleValidWords.contains('RAWON'), isTrue);
      expect(kKulinerdleValidWords.contains('BAKSO'), isTrue);
      expect(kKulinerdleValidWords.contains('TEMPE'), isTrue);
      expect(kKulinerdleValidWords.contains('ZZZZZ'), isFalse);
    });
  });
}
