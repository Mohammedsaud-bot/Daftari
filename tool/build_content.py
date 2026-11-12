import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from words_data import WORDS
from lessons_data import LESSONS
from word_images import WORD_IMAGE
path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'content', 'book12.json')
d = json.load(open(path, encoding='utf-8'))
base_ids = {w['id'] for w in d['words']}
for unit, items in WORDS.items():
    for (i, word, ar, sym, df, ex, exar) in items:
        assert i not in base_ids, i
        d['words'].append(dict(id=i, word=word, ar=ar, definition=df, example=ex, exampleAr=exar, symbol=sym, image=WORD_IMAGE[i]))
        base_ids.add(i)
keep = [l for l in d['lessons'] if l['id'] in ('travel-1', 'foundation-1')]
d['lessons'] = keep[:1] + LESSONS + keep[1:]
for u in d['units']:
    u['available'] = True
d['units'][4]['topicsAr'] = 'مراجعة مفردات وقواعد الوحدات الأربع'
# validate
wid = {w['id'] for w in d['words']}; sids = set(); lids = set()
for l in d['lessons']:
    assert l['id'] not in lids; lids.add(l['id'])
    assert l['unit'] in {u['id'] for u in d['units']} | {'foundation'}, l['unit']
    for s in l['steps']:
        assert s['id'] not in sids, s['id']; sids.add(s['id'])
        k = s['kind']; assert k in ('intro','vocabulary','choice','listening','grammar','order'), k
        for f in ('ar','en'): assert s[f]
        if k == 'vocabulary':
            for w in s['words']: assert w in wid, w
        if k == 'choice': assert s['answer'] in s['options'], s['id']; assert len(set(s['options']))==len(s['options'])
        if k == 'order': assert ' '.join(s['options']) != s['answer'] and sorted(s['options']) == sorted(s['answer'].split(' ')), s['id']
        if k in ('choice','order'): assert s['explanationAr'] and s['explanationEn'] and s['promptAr'] and s['promptEn']
        if k == 'grammar': assert s['formula'] and s['example']
        if k == 'listening': assert s['audio'] and s['translation']
for u in d['units']:
    assert any(l['unit'] == u['id'] for l in d['lessons']), u['id']
json.dump(d, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('words', len(d['words']), 'lessons', len(d['lessons']), 'steps', len(sids), 'questions', sum(1 for l in d['lessons'] for s in l['steps'] if 'answer' in s))
for u in d['units']: print(u['id'], [l['id'] for l in d['lessons'] if l['unit']==u['id']])
