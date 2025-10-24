// lib/data/disease_info.dart

class DiseaseInfo {
  final String title;
  final String generalInfo;
  final String symptoms;
  final String careTips;

  const DiseaseInfo({
    required this.title,
    required this.generalInfo,
    required this.symptoms,
    required this.careTips,
  });
}

// === Disease data map ===
final Map<String, DiseaseInfo> diseaseData = {
  'healthy': DiseaseInfo(
    title: 'Healthy Leaf',
    generalInfo:
        'A healthy calamansi leaf displays a uniform green color, smooth texture, and natural gloss. It indicates proper nutrition, water balance, and the absence of insect or pathogen activity.',
    symptoms:
        'No discoloration, curling, or spots. Leaf size and shape are consistent, and the surface is intact and clean.',
    careTips:
        'Maintain balanced watering, proper sunlight exposure, and regular fertilization with micronutrients like zinc and magnesium. Ensure good air circulation and monitor for early signs of disease or pests.',
  ),
  'leaf miner': DiseaseInfo(
    title: 'Leaf Miner',
    generalInfo:
        'Leaf miners are larvae of small moths (Phyllocnistis citrella) that tunnel through the leaf tissue of citrus plants, particularly young leaves. The larvae feed between leaf surfaces, creating winding tunnels that disrupt photosynthesis.',
    symptoms:
        'Silvery or whitish winding trails visible on young leaves. Leaves may curl, fold, or distort due to larval feeding. Severe infestation can stunt young plant growth and make trees vulnerable to other pathogens.',
    careTips:
        'Prune and destroy infested shoots to prevent further spread. Apply horticultural or neem oil on young flushes to deter adult moths. Encourage beneficial insects like parasitic wasps and avoid excessive nitrogen fertilization, which attracts new flush growth that leaf miners prefer.',
  ),
  'canker': DiseaseInfo(
    title: 'Citrus Canker',
    generalInfo:
        'Citrus canker is a highly contagious bacterial disease caused by Xanthomonas citri pv. citri. It infects leaves, stems, and fruit, spreading through rain splash, wind, and contaminated tools.',
    symptoms:
        'Small, water-soaked or oily-looking spots that enlarge into raised corky lesions with a distinct yellow halo. Severe infections lead to defoliation, twig dieback, and fruit blemishes or drop.',
    careTips:
        'Remove and burn infected plant parts to prevent spread. Disinfect pruning tools after each use. Avoid overhead irrigation and use copper-based bactericides as a preventive measure during wet seasons.',
  ),
  'greening': DiseaseInfo(
    title: 'Citrus Greening (Huanglongbing / HLB)',
    generalInfo:
        'Citrus greening, also known as Huanglongbing (HLB), is a destructive bacterial disease caused by Candidatus Liberibacter species and transmitted by the Asian citrus psyllid. It disrupts nutrient flow in the plant’s phloem tissue.',
    symptoms:
        'Mottled yellow and green blotches on leaves, often asymmetrical between leaf halves. Leaves may become small, thick, and leathery. Infected trees show twig dieback, sparse foliage, and small, misshapen fruit that remains green at one end.',
    careTips:
        'Immediately remove and properly dispose of infected trees. Control psyllid populations through approved insecticides and biological control. Always plant disease-free certified seedlings and monitor trees regularly for early signs of HLB.',
  ),
  'black spot': DiseaseInfo(
    title: 'Citrus Black Spot',
    generalInfo:
        'Citrus black spot is a fungal disease caused by Phyllosticta citricarpa (Guignardia citricarpa). It primarily affects leaves and fruit, causing lesions and reducing fruit quality and yield.',
    symptoms:
        'Dark brown to black circular spots with gray or tan centers on leaves. Some lesions develop small raised black dots (pycnidia). Severe infections can cause premature leaf and fruit drop.',
    careTips:
        'Collect and destroy fallen leaves and fruit to reduce fungal spores. Apply recommended fungicides during humid or rainy periods. Ensure good air circulation in the canopy and avoid water stagnation.',
  ),
};
