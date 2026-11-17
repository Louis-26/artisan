# Artisan Benchmark Dataset

## ArtVIP
- Input: Text and one open-state reference image
- Case number: 50
- Description: distinct objects in daily life, with text prompt and one open-state reference image for each object. 
- Purpose: target commonly seen daily life 3D objects and test **fidelity and collision** of the generated 3D objects
```bash
cd $(git rev-parse --show-toplevel)
ls -1 benchmark/data/ArtVIP | wc -l
```
 

## LightWheel
- Input: Text and one open-state reference image
- Case number: 50
- Description: objects appearing in kitchen, composed of 14 groups, where each group contains the same type of objects with different sizes 

```bash
cd $(git rev-parse --show-toplevel)
# case number: 50
ls -1 benchmark/data/LightWheel | wc -l
# group number: 14
ls -1 benchmark/data/LightWheel | sed -E 's/[0-9_]+$//' | sort -u | wc -l
```
 

## Stability
- Input: pure text for description of each object
- Case number: 50
- Description: given pure text description, generate 3D objects prone to fall down in practice
- Purpose: target less stable 3D objects in practice, and test **stability** of the generated objects in simulator
```bash
cd $(git rev-parse --show-toplevel)
# case number: 50
ls -1 benchmark/data/Stability | wc -l
```

## ABO-Mass
- Input: short text prompt, mass, and one reference image
- Case number: 50
- Description: objects with different mass and shape explicitly specified, taken from Amazon-Berkeley Objects (ABO) dataset
- Purpose: target 3D objects with different mass and shape, and test whether **mass**, an important physical property, is correctly reflected in the generated 3D objects  
```bash
cd $(git rev-parse --show-toplevel)
# case number: 50
ls -1 benchmark/data/ABO-Mass | wc -l
```

## Reference
link: https://huggingface.co/datasets/mastercai/Artisan-Benchmark





