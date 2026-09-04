import re

with open('src/client/GuestRenderer.luau', 'r', encoding='utf-8') as f:
    code = f.read()

# Use regex to find and remove the face decal destroy block, plus all the model:WaitForChild stuff that is no longer needed.
# Since we create all parts synchronously now, we don't need any of these WaitforChild calls in arrive()

target_regex = r"\tlocal head = model:WaitForChild.*?faceDecal:Destroy\(\)\n\t\tend\n\tend"
code = re.sub(target_regex, "", code, flags=re.DOTALL)

with open('src/client/GuestRenderer.luau', 'w', encoding='utf-8') as f:
    f.write(code)
