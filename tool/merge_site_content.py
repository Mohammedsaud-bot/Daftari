"""Merge the content of the ALC Book 12 interactive notebook (أ. محمد المطيري)
into book12.json as extra sessions inside each unit.

Source data lives in tool/site_data/*.js (first option of every question is the
correct answer). Regenerate the JSON snapshot and merge with:

    node -e 'const r=require("./tool/site_data/rules.js"),p=require("./tool/site_data/practice.js"),b=require("./tool/site_data/bookex.js");require("fs").writeFileSync("tool/site_data/site_data.json",JSON.stringify({...r,...p,...b}))'
    python3 tool/merge_site_content.py

The script is idempotent: it removes any lesson whose id starts with "alc-"
before adding the merged sessions again.
"""
import json, os, random, re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
CONTENT = os.path.join(ROOT, 'assets', 'content', 'book12.json')
SITE = os.path.join(ROOT, 'tool', 'site_data', 'site_data.json')

UNIT = {1: 'travel', 2: 'education', 3: 'home', 4: 'outdoors'}
PREFIX = 'alc-'

STORY_AR = ("اسمي ماجد، وأنا في السلك العسكري منذ اثنتي عشرة سنة. عندما كنت طفلًا، كانت عائلتي تسكن في بلدة صغيرة قرب الجبال. "
            "كل شتاء كان أبي يأخذني للصيد، وفي الصيف كنا نذهب لصيد السمك عند بحيرة هادئة. كنت أظن أن صيد السمك ممل، لكنني الآن أجده مريحًا جدًا. "
            "في السنة الماضية اتخذت قرارًا مهمًا عن مستقبلي. قررت أن آخذ بعض المواد في الجامعة لأحصل على شهادة البكالوريوس. "
            "لم أنهِ شهادتي بعد، لكنني أخذت ست مواد حتى الآن. قالت زوجتي إنها متحمسة جدًا لذلك. "
            "وأضفنا أيضًا غرفة جلوس عائلية إلى بيتنا في الضاحية، لأننا كنا نحتاج إلى مساحة أكبر. "
            "إذا كان الجو جميلًا هذا الأسبوع، فسنقيم تجمعًا في الجلسة الخارجية الجديدة. أخي لا يستطيع الحضور، لذلك قد يزورنا الشهر القادم.")

ANYMORE = dict(id='anymore', word='anymore', ar='لم يعد (في النفي)',
               definition='Not now, although it was true before. Use it with not at the end of a sentence.',
               example="Sam graduated last year. He isn't a student anymore.",
               exampleAr='تخرّج سام السنة الماضية. لم يعد طالبًا.', symbol='school')


def clean(html):
    t = re.sub(r'<[^>]+>', '', html)
    return re.sub(r'\s+', ' ', t).replace('‎', '').strip()


def shuffled(options, seed):
    opts = list(options)
    rnd = random.Random(seed)
    rnd.shuffle(opts)
    return opts


def question(qid, text, options, why, ctx_ar):
    # A question written in Arabic-free English: the sentence goes in `example`, the prompt stays short.
    has_blank = '___' in text
    prompt_ar = 'اختر الكلمة المناسبة للفراغ.' if has_blank else 'اختر الإجابة الصحيحة.'
    prompt_en = 'Choose the best answer for the blank.' if has_blank else 'Choose the correct answer.'
    return dict(id=qid, kind='choice', ar=ctx_ar, en='Practice question',
                promptAr=prompt_ar, promptEn=prompt_en, example=text,
                options=shuffled(options, qid), answer=options[0],
                explanationAr=why, explanationEn=f'Correct answer: {options[0]}')


def rule_lesson(i, r, viz):
    lid = f'{PREFIX}rule-{i + 1}'
    ex = [(clean(e), a) for e, a in r['ex']]
    steps = [dict(id=f'{lid}-g', kind='grammar', ar=r['t'], en=r['e'],
                  bodyAr=clean(r['x']),
                  bodyEn=f"{r['e']}. Study the formula and the example, then practise with ten questions.",
                  example=ex[0][0], translation=ex[0][1], formula=r['f'])]
    more = ex[1:]
    steps.append(dict(id=f'{lid}-ex', kind='intro', ar='أمثلة من القاعدة', en='More examples',
                      bodyAr='\n'.join(f'• {e}\n   {a}' for e, a in more),
                      bodyEn='\n'.join(f'• {e}' for e, _ in more),
                      example=more[-1][0], translation=more[-1][1]))
    table = viz.get(r['e'])
    body = f"❌ {r['m'][0]}\n✅ {r['m'][1]}\n\n💡 {r['tip']}"
    if table:
        body += '\n\n' + '\n'.join(' | '.join(row) for row in table)
    steps.append(dict(id=f'{lid}-tip', kind='intro', ar='انتبه من هذا الخطأ', en='Common mistake',
                      bodyAr=body, bodyEn=f"Wrong: {r['m'][0]}\nRight: {r['m'][1]}",
                      example=r['m'][1], translation=r['tip']))
    for k, (text, options, why) in enumerate(r['q']):
        steps.append(question(f'{lid}-q{k + 1}', text, options, why, r['t']))
    return dict(id=lid, unit=UNIT[r['l']], ar=f"القاعدة: {r['t']}", en=r['e'],
                minutes=8, source='alc-notebook', steps=steps)


def book_lesson(i, b):
    lid = f'{PREFIX}book-{i + 1}'
    kind, _, exercise = b['src'].split(' · ')
    label_ar = 'الواجب' if kind == 'Homework' else 'التقييم'
    steps = [dict(id=f'{lid}-intro', kind='intro', ar=f'تمارين الكتاب: {label_ar}', en=b['src'],
                  bodyAr=f"أسئلة اختيار من قسم {label_ar} ({kind}) في آخر كتاب 12، الدرس {b['l']} — {exercise}. عددها {len(b['q'])} سؤال.",
                  bodyEn=f"Multiple-choice questions from the {kind} section of Book 12, Lesson {b['l']}, {exercise}.")]
    for k, (text, options, why) in enumerate(b['q']):
        steps.append(question(f'{lid}-q{k + 1}', text, options, why, f'{label_ar} · {exercise}'))
    return dict(id=lid, unit=UNIT[b['l']], ar=f'تمارين الكتاب: {label_ar} — {exercise}', en=b['src'],
                minutes=max(4, len(b['q']) // 2), source='alc-notebook', steps=steps)


def chunks(seq, n):
    return [seq[i:i + n] for i in range(0, len(seq), n)]


def opposites_lesson(opp, oq, verbs):
    lid = f'{PREFIX}opposites'
    steps = []
    for k, part in enumerate(chunks(opp, 6)):
        steps.append(dict(id=f'{lid}-pairs-{k + 1}', kind='intro', ar=f'الأضداد ({k + 1}/{len(opp) // 6})', en='Opposites',
                          bodyAr='\n'.join(f'{a} ({aa})  ⇄  {b} ({ba})' for a, aa, b, ba in part),
                          bodyEn='\n'.join(f'{a}  ⇄  {b}' for a, _, b, _ in part),
                          example=f'{part[0][0]} ⇄ {part[0][2]}', translation=f'{part[0][1]} ⇄ {part[0][3]}'))
    for k, part in enumerate(chunks(verbs, 6)):
        steps.append(dict(id=f'{lid}-verbs-{k + 1}', kind='intro', ar=f'أفعال شاذة ({k + 1}/{len(verbs) // 6})', en='Irregular verbs',
                          bodyAr='\n'.join(f'{v} → {p}  :  {a}' for v, p, a in part),
                          bodyEn='\n'.join(f'{v} → {p}' for v, p, _ in part),
                          example=f'{part[0][0]} → {part[0][1]}', translation=part[0][2]))
    for k, (text, options, why) in enumerate(oq):
        steps.append(question(f'{lid}-q{k + 1}', text, options, why, 'تمارين الأضداد'))
    return dict(id=lid, unit='review', ar='الأضداد والأفعال الشاذة', en='Opposites and irregular verbs',
                minutes=10, source='alc-notebook', steps=steps)


def listening_lesson(story, lq):
    lid = f'{PREFIX}listening'
    steps = [dict(id=f'{lid}-intro', kind='intro', ar='الاستماع: قصة ماجد', en="Listening: Majed's story",
                  bodyAr='اسمع القصة، وتقدر تعيدها ببطء. حاول تجاوب قبل ما تفتح النص. القصة تجمع قواعد الكتاب كلها: used to و would والمضارع التام والكلام المنقول والشرط.',
                  bodyEn="Listen to Majed's story. Try to answer before you read the transcript. It reviews the grammar of the whole book.",
                  example="My name is Majed, and I've been in the military for twelve years.",
                  translation='اسمي ماجد، وأنا في السلك العسكري منذ اثنتي عشرة سنة.'),
             dict(id=f'{lid}-story', kind='listening', ar='قصة ماجد', en="Majed's story",
                  bodyAr='استمع مرة، ثم استمع ببطء إذا احتجت. جرّب الفهم قبل فتح النص.',
                  bodyEn='Listen once, then try the slower speed if you need it.',
                  audio=story, translation=STORY_AR, speakersAr='قصة ماجد', speakersEn="MAJED'S STORY")]
    for k, (text, options, why) in enumerate(lq):
        steps.append(question(f'{lid}-q{k + 1}', text, options, why, 'أسئلة الاستماع'))
    return dict(id=lid, unit='review', ar='الاستماع: قصة ماجد + 10 أسئلة', en="Listening: Majed's story",
                minutes=8, source='alc-notebook', steps=steps)


def main():
    d = json.load(open(CONTENT, encoding='utf-8'))
    s = json.load(open(SITE, encoding='utf-8'))
    lessons = [l for l in d['lessons'] if not l['id'].startswith(PREFIX)]
    if not any(w['id'] == 'anymore' for w in d['words']):
        d['words'].append(ANYMORE)

    extra = {u: [] for u in list(UNIT.values()) + ['review']}
    for i, r in enumerate(s['RULES']):
        extra[UNIT[r['l']]].append(rule_lesson(i, r, s['VIZ']))
    for i, b in enumerate(s['BOOKEX']):
        extra[UNIT[b['l']]].append(book_lesson(i, b))
    extra['review'] += [opposites_lesson(s['OPP'], s['OQ'], s['VERBS']), listening_lesson(s['STORY'], s['LQ'])]

    merged = []
    for unit in [u['id'] for u in d['units']]:
        merged += [l for l in lessons if l['unit'] == unit] + extra.get(unit, [])
    merged += [l for l in lessons if l['unit'] not in {u['id'] for u in d['units']}]  # foundation stays last
    d['lessons'] = merged

    # validate (same rules as build_content.py)
    wid = {w['id'] for w in d['words']}
    sids, lids = set(), set()
    for l in d['lessons']:
        assert l['id'] not in lids, l['id']; lids.add(l['id'])
        for st in l['steps']:
            assert st['id'] not in sids, st['id']; sids.add(st['id'])
            assert st['ar'] and st['en'], st['id']
            if st['kind'] == 'vocabulary':
                assert all(w in wid for w in st['words']), st['id']
            if st['kind'] == 'choice':
                assert st['answer'] in st['options'] and len(set(st['options'])) == len(st['options']), st['id']
                assert st['explanationAr'] and st['explanationEn'] and st['promptAr'] and st['promptEn'], st['id']
            if st['kind'] == 'grammar':
                assert st['formula'] and st['example'], st['id']
            if st['kind'] == 'listening':
                assert st['audio'] and st['translation'], st['id']
    json.dump(d, open(CONTENT, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    added = [l for l in d['lessons'] if l['id'].startswith(PREFIX)]
    print('lessons', len(d['lessons']), 'added', len(added),
          'added questions', sum(1 for l in added for st in l['steps'] if 'answer' in st),
          'words', len(d['words']))
    for u in d['units']:
        print(u['id'], [l['id'] for l in d['lessons'] if l['unit'] == u['id']])


if __name__ == '__main__':
    main()
