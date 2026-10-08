import json
from pathlib import Path

base_translation = Path("assets/translations/en.json")

with open(base_translation, encoding="utf-8") as f:
	data = json.load(f)

# The raw keyname path is shown when a translation is missing.
# Since locales also fallback to english, it was hard to tell when the translation was working. 
def replace(data):
	if isinstance(data, dict):
		return {key: replace(data) for key, data in data.items()}
	return "xxx" if isinstance(data, str) else data

# Uses 'af' as it is a valid language code and we probably won't have it translated to this (unless Resonite adds it as well)
with open("assets/translations/af.json", "w", encoding="utf-8") as f:
	json.dump(replace(data), f, indent="\t", ensure_ascii=False)
	f.write("\n")