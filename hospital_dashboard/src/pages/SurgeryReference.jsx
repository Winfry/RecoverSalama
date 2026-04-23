import { useState } from "react";

const surgeries = [
  {
    id: 1, code: "C-SECTION", name: "Caesarean Section", specialty: "Obstetrics",
    color: "#e1f5ee", accent: "#0f6e56",
    overview: "The world's most performed major surgery. A baby is delivered through incisions in the abdominal wall (laparotomy) and uterus (hysterotomy). Global rates have risen from ~6% in 1990 to 21% in 2018, exceeding 50% in some middle-income countries. In Kenya it is the single most performed major surgery.",
    indications: ["Labour dystocia / failure to progress", "Foetal distress / non-reassuring CTG", "Malpresentation (breech, transverse)", "Placenta praevia / accreta", "Prior uterine surgery", "Eclampsia / severe pre-eclampsia", "Cord prolapse"],
    procedure: "Pfannenstiel or midline skin incision → rectus sheath incision → bladder flap → lower-segment uterine incision → delivery of neonate → placenta delivery → uterine closure in 1–2 layers → layered abdominal closure. Spinal anaesthesia is gold-standard; GA reserved for emergencies. Duration: 30–60 min.",
    complications: ["Haemorrhage (leading cause of severe maternal morbidity)", "Wound infection / endometritis", "DVT / pulmonary embolism", "Bowel obstruction (OR 2.92× vs vaginal birth)", "Incisional hernia (OR 2.71×)", "Bladder/ureter injury", "Placenta accreta in future pregnancies"],
    diet: {
      label: "Full Custom Protocol (ERAS-Based)",
      badge: "✅ Custom",
      badgeColor: "#0f6e56",
      pre: [
        "Night before: 100 g carbohydrate drink (e.g. 32 oz apple juice)",
        "2 hours before arrival: 50 g carbohydrate drink (16 oz apple juice)",
        "Immunonutrition (IMN) 5 days pre-op if at nutrition risk: arginine + omega-3 + antioxidants",
        "High-protein meals: target 1.5 g/kg/day protein pre-op",
        "Iron-rich foods if anaemic: red meat, lentils, dark greens"
      ],
      post: [
        "Hours 0–4: nil by mouth (anaesthesia clearance)",
        "Hours 4–8: clear liquids — water, broth, oral rehydration salts; sip slowly",
        "Day 1: soft bland diet — porridge, ugali, soft bread, boiled potatoes, fruit juice; NO carbonated drinks",
        "Day 2–3: semi-solid foods; prioritise lean protein (eggs, fish, chicken)",
        "Day 4–7: full diet with iron + vitamin C combinations; avoid constipation triggers",
        "Weeks 2–6: high-fibre diet to prevent straining on wound; 1.5–2 L water daily",
        "Breastfeeding mothers: +500 kcal/day; calcium-rich foods (milk, yoghurt, omena)",
        "Avoid: alcohol, raw fish, high-mercury fish, excessive caffeine while breastfeeding"
      ],
      keyNutrients: "Iron, Vitamin C, Calcium, Zinc, Omega-3, Protein (≥1.5 g/kg/day)"
    },
    research: [
      { title: "Evidence-based surgical procedures to optimise caesarean outcomes", journal: "eClinicalMedicine / The Lancet", year: 2024, url: "https://www.thelancet.com/journals/eclinm/article/PIIS2589-5370(24)00211-6/fulltext", note: "Overview of 38 systematic reviews, 628 RCTs, 190,349 participants. First ever SR-of-SRs on CS surgical procedures." },
      { title: "Guidelines for postoperative care in cesarean delivery: ERAS Society (2025 update)", journal: "American Journal of Obstetrics & Gynecology", year: 2025, url: "https://www.ajog.org/article/S0002-9378(25)00071-7/fulltext", note: "Most current ERAC protocol; evidence search January 2017–September 2024. Covers analgesia, early feeding, mobilisation." },
      { title: "Surgical complications after caesarean section: population-based cohort (79,052 women)", journal: "PLOS ONE / PMC", year: 2021, url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8491947/", note: "CS associated with 2.92× bowel obstruction risk and 2.71× incisional hernia risk vs vaginal delivery." },
      { title: "The research frontier of cesarean section recovery: bibliometric analysis", journal: "Frontiers in Medicine", year: 2022, url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC9792604/", note: "Trends in ERAS application to CS; rising research output globally." },
      { title: "Practice of Enhanced Recovery after Caesarean Delivery in resource-limited setting", journal: "PMC (Ethiopia)", year: 2024, url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC10783380/", note: "Postoperative ERAC adherence was only ~40% in SSA hospitals. Early oral intake was key gap." }
    ]
  },
  {
    id: 2, code: "HERNIA", name: "Inguinal Hernia Repair", specialty: "General Surgery",
    color: "#e6f1fb", accent: "#185fa5",
    overview: "One of the most commonly performed operations worldwide (~800,000/year in the US alone). Inguinal hernias occur when abdominal contents protrude through the inguinal canal. More common in males (lifetime risk ~27% vs 3% females). Three main approaches: open (Lichtenstein mesh), laparoscopic (TEP/TAPP), and robotic. Robotic use increased 1.9%/year (JAMA Surgery 2024).",
    indications: ["Symptomatic inguinal hernia", "Strangulated or incarcerated hernia (emergency)", "Large hernias with risk of incarceration", "Bilateral hernias (laparoscopic preferred)", "Recurrent hernia"],
    procedure: "Open (Lichtenstein): groin incision → hernia sac dissection → mesh placement over defect → suture fixation → closure. Duration ~60–90 min. Laparoscopic TEP: 3 trocars → extraperitoneal dissection → large mesh covering myopectineal orifice. Robotic: similar to laparoscopic with robotic arms. All techniques show comparable safety (propensity-matched 2024 study).",
    complications: ["Chronic inguinodynia (groin pain) — most common long-term issue", "Recurrence (1–5% with mesh)", "Mesh infection", "Injury to vas deferens / testicular vessels", "Haematoma / seroma", "Nerve injury (ilioinguinal, genitofemoral)"],
    diet: {
      label: "High-Fibre Anti-Straining Protocol",
      badge: "✅ Custom",
      badgeColor: "#185fa5",
      pre: [
        "Start high-fibre diet 1 week pre-op to establish regular bowel habit",
        "Increase fluids to 2 L/day",
        "Carbohydrate loading night before and 2 hours before (same as C-Section protocol)",
        "Avoid foods causing bloating/gas (beans, cabbage, carbonated drinks)"
      ],
      post: [
        "Day 0–1: clear liquids; gentle sips; avoid straining at all costs",
        "Day 2–3: soft low-fibre foods (white rice, boiled eggs, banana, boiled fish)",
        "Day 4–7: gradually reintroduce fibre; avoid heavy lifting/straining",
        "Week 2–6: HIGH-FIBRE diet critical — fruits, vegetables, whole grains, legumes",
        "Stool softeners if needed; 2+ L water daily",
        "Avoid: spicy foods, carbonated drinks, alcohol (increase intra-abdominal pressure)",
        "Protein: 1.2–1.5 g/kg/day to support mesh integration and wound healing"
      ],
      keyNutrients: "Fibre (25–35 g/day), Protein, Water, Zinc for wound healing"
    },
    research: [
      { title: "Open vs laparoscopic vs robotic inguinal hernia repair: systematic review 2025", journal: "PMC / MDPI", year: 2025, url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC11818799/", note: "All three techniques safe; robotic reduces conversion to open (2.4% vs 10.7% laparoscopic, JAMA Surg 2024)." },
      { title: "Open versus laparoscopic versus robotic inguinal hernia repair: propensity-matched outcome analysis", journal: "Surgery (Elsevier)", year: 2024, url: "https://pubmed.ncbi.nlm.nih.gov/39472265/", note: "All techniques safe and effective; open more common in comorbid patients." },
      { title: "Effect of early vs late inguinal hernia repair in preterm infants: RCT", journal: "JAMA", year: 2024, url: "https://pubmed.ncbi.nlm.nih.gov/38530261/", note: "Addresses timing debate in paediatric hernia; JAMA 2024." }
    ]
  },
  {
    id: 3, code: "APPY", name: "Appendectomy", specialty: "General Surgery",
    color: "#faece7", accent: "#993c1d",
    overview: "Removal of the vermiform appendix, usually for acute appendicitis. Shortest mean OR time of the 15 common procedures (~51 minutes). Lifetime risk of appendicitis is ~7–8%. Laparoscopic appendectomy (LA) is now the global standard in well-resourced settings; open (McBurney incision) remains common in low-resource environments. Perforated appendicitis requires urgent surgery.",
    indications: ["Acute appendicitis", "Perforated appendicitis", "Appendiceal abscess (interval appendectomy)", "Appendiceal mucocele", "Incidental during laparoscopy for other conditions"],
    procedure: "Laparoscopic: 3-port technique → pneumoperitoneum → identification of appendix → ligation of mesoappendix → stapler or ligature division of appendix base → extraction via port. Open: McBurney incision → identification → ligation → wound closure. Perforated: irrigation + drain. Duration 30–60 min.",
    complications: ["Wound infection (higher open vs laparoscopic)", "Intra-abdominal abscess (especially perforated)", "Stump leak / blowout", "Ileus", "Port-site hernia (laparoscopic)"],
    diet: {
      label: "Low → High Fibre Stepwise Protocol",
      badge: "✅ Custom",
      badgeColor: "#993c1d",
      pre: [
        "If elective/interval: full meal up to 6 hours before; clear liquids up to 2 hours",
        "Emergency: NBM immediately on diagnosis",
        "No specific pre-op dietary restriction beyond standard fasting"
      ],
      post: [
        "Day 0 (post-op): clear liquids when alert — water, broth, oral rehydration salts",
        "Day 1: low-fibre soft diet — white rice, toast, boiled potato, banana, boiled chicken",
        "Day 2–3: add soft-cooked vegetables; avoid raw foods and legumes",
        "Day 4–7: gradually increase fibre; add fruits, soft-cooked lentils",
        "Week 2+: full HIGH-FIBRE diet; 2 L water daily to prevent constipation",
        "Perforated appendicitis: slower progression; may need IV nutrition initially",
        "Protein 1.2 g/kg/day for wound healing"
      ],
      keyNutrients: "Protein, Zinc, Vitamin C (wound healing), Probiotics (post-antibiotic)"
    },
    research: [
      { title: "Laparoscopic vs open appendectomy: meta-analyses in low-resource settings", journal: "Multiple PMC reviews", year: 2023, url: "https://pmc.ncbi.nlm.nih.gov/", note: "Laparoscopic shows fewer wound infections; open remains more accessible in Africa." },
      { title: "Repair of umbilical hernias concomitant to other procedures including appendectomy", journal: "Hernia (Springer)", year: 2024, url: "https://pubmed.ncbi.nlm.nih.gov/38488931/", note: "Appendectomy safely combined with umbilical hernia repair; comparable 90-day outcomes." }
    ]
  },
  {
    id: 4, code: "LAPAROTOMY", name: "Laparotomy (Exploratory)", specialty: "General Surgery",
    color: "#f1efe8", accent: "#5f5e5a",
    overview: "A large abdominal incision (midline or transverse) to explore the abdominal cavity for unknown pathology. Used when less invasive imaging/interventions are insufficient or unavailable. Remains a critical operation in sub-Saharan Africa where advanced imaging and laparoscopy are limited. The 'Surgical Apgar Score' predicts post-laparotomy complications (Dullo et al., Annals of African Surgery).",
    indications: ["Peritonitis (perforated viscus)", "Trauma (haemoperitoneum)", "Bowel obstruction not resolving", "Abdominal mass requiring surgical staging", "Ectopic pregnancy rupture", "Post-operative complications"],
    procedure: "Midline incision (umbilicus to pubis or xiphoid) → systematic four-quadrant exploration → identification and management of pathology → haemostasis → irrigation if contaminated → closure (mass closure technique preferred to reduce hernia risk). Duration variable: 1–5 hours.",
    complications: ["Wound dehiscence", "Incisional hernia (20–30% long-term)", "Adhesions → small bowel obstruction", "Intra-abdominal sepsis", "Anastomotic leak", "Prolonged ileus"],
    diet: {
      label: "Modified C-Section Protocol (General Abdominal)",
      badge: "⚠️ Modified",
      badgeColor: "#5f5e5a",
      pre: ["Standard ERAS carbohydrate loading protocol", "Nutritional optimisation if elective — correct malnutrition first", "Immunonutrition 5 days pre-op if nutritional risk identified"],
      post: [
        "Post-op: NBM until bowel sounds return and/or flatus passed",
        "Early oral feeding within 24–48h if no anastomosis or perforation",
        "Start with clear liquids → progress to soft diet over 3–5 days",
        "High-protein diet: 1.5 g/kg/day — eggs, fish, legumes",
        "Avoid high-fibre until bowel confirmed functional",
        "Bowel rest protocol if anastomosis performed: stricter progression",
        "Monitor for signs of ileus: no advancement if vomiting/distension"
      ],
      keyNutrients: "Protein, Glutamine, Zinc, Vitamin A (wound healing), Electrolytes"
    },
    research: [
      { title: "Surgical Apgar Score Predicts Post-Laparotomy Complications", journal: "Annals of African Surgery", year: 2022, url: "https://www.annalsofafricansurgery.com/10-2", note: "Dullo et al.; Kenyan data — Surgical Apgar Score validated for SSA laparotomy outcomes." },
      { title: "Closure methods for laparotomy incisions for preventing incisional hernias", journal: "Cochrane Database of Systematic Reviews", year: 2017, url: "https://pubmed.ncbi.nlm.nih.gov/29099149/", note: "Patel et al.; mass closure with slowly absorbable suture reduces hernia risk." }
    ]
  },
  {
    id: 5, code: "HYST", name: "Hysterectomy", specialty: "Gynaecology",
    color: "#fbeaf0", accent: "#993556",
    overview: "Surgical removal of the uterus. The most common non-obstetric major surgery in women worldwide. Approaches: abdominal (TAH), vaginal (VH), laparoscopic (TLH/LAVH), and robotic. In Kenya, abdominal hysterectomy predominates due to resource constraints. Uterine fibroids are the leading indication in Africa. ERAS protocols now well-established for gynaecological surgery.",
    indications: ["Uterine fibroids (myomas) — most common in Kenya/Africa", "Abnormal uterine bleeding unresponsive to medical treatment", "Endometriosis / adenomyosis", "Uterine prolapse", "Gynaecological cancers (cervical, endometrial, ovarian)", "Postpartum haemorrhage (obstetric hysterectomy)"],
    procedure: "TAH: Pfannenstiel or midline incision → ligation of uterine vessels → division of cardinal and uterosacral ligaments → cervical transection → vault closure → abdominal closure. Duration 1–2 hours. Laparoscopic: 3–4 ports → same steps robotically/endoscopically.",
    complications: ["Haemorrhage", "Bladder/ureter injury", "Bowel injury", "Vault dehiscence", "Lymphocele (if radical)", "DVT/PE", "Premature menopause (if ovaries removed)", "Pelvic floor dysfunction"],
    diet: {
      label: "Modified C-Section Protocol + Hormonal Considerations",
      badge: "⚠️ Modified",
      badgeColor: "#993556",
      pre: ["ERAS carbohydrate loading (same as C-Section)", "Correct iron-deficiency anaemia pre-op (common with fibroids/heavy bleeding)", "Immunonutrition 5 days pre-op if eligible", "High-protein diet 2 weeks pre-op"],
      post: [
        "Day 0: clear liquids 4 hours post-op (ERAS GYN protocol)",
        "Day 1: low-fat, low-fibre bland diet — ERAS GYN 'First Foods' protocol",
        "Day 2–5: progress to full diet; no fried, spicy, or high-fibre foods initially",
        "Week 2+: anti-inflammatory diet — omega-3 (fish, flaxseed), colourful vegetables",
        "Iron supplementation if ovaries retained and pre-op anaemia",
        "If bilateral oophorectomy: calcium (1200 mg/day) + Vitamin D3 for bone protection",
        "Phytoestrogens may help menopausal symptoms: soy, flaxseed (evidence modest)"
      ],
      keyNutrients: "Iron, Calcium, Vitamin D, Omega-3, Protein"
    },
    research: [
      { title: "ERAS for gynaecological surgery: evidence and implementation", journal: "ESPEN / Clinical Nutrition", year: 2021, url: "https://www.clinicalnutritionjournal.com/article/S0261-5614(21)00178-3/fulltext", note: "ERAS shown effective for hysterectomy, gynaecologic oncology cases." },
      { title: "ERAS GYN Nutrition Guidelines — MD Anderson Cancer Center", journal: "MD Anderson / ERAS Society", year: 2023, url: "https://www.mdanderson.org/content/dam/mdanderson/documents/Departments-and-Divisions/Gynecologic-Oncology/ERAS-GYN%20Nutrition%20Guidelines.pdf", note: "Low-fat, low-fibre diet started 4 hours post-op; immunonutrition pre-op 5–7 days." }
    ]
  },
  {
    id: 6, code: "FRACTURE", name: "Open Fracture Repair (ORIF)", specialty: "Orthopaedics",
    color: "#eaf3de", accent: "#3b6d11",
    overview: "Open reduction and internal fixation of fractured bones using plates, screws, intramedullary nails, or external fixators. Road traffic accidents (RTAs) are the dominant cause in Kenya and Sub-Saharan Africa. Kenyatta National Hospital (KNH) has one of East Africa's largest trauma loads. Femoral shaft fractures are treated with intramedullary nailing; Njoroge et al. (AAS) documented outcomes in Kenya.",
    indications: ["Displaced fractures requiring anatomic reduction", "Intra-articular fractures", "Open (compound) fractures", "Fractures with neurovascular compromise", "Road traffic accident injuries", "Pathological fractures"],
    procedure: "Fracture exposed/reduced → temporary K-wire fixation → plate and screws OR intramedullary nail inserted → fluoroscopy confirmation → wound closure. Open fractures require urgent irrigation and debridement first (within 6 hours ideal). Duration 1–4 hours depending on complexity.",
    complications: ["Infection / osteomyelitis (especially open fractures)", "Non-union / malunion", "Implant failure", "AVN (avascular necrosis) of femoral head", "DVT/PE", "Compartment syndrome", "Fat embolism"],
    diet: {
      label: "Bone Healing High-Calcium/Protein Protocol",
      badge: "⚠️ Modified",
      badgeColor: "#3b6d11",
      pre: ["Emergency: NBM immediately; IV fluids for trauma stabilisation", "Elective: ERAS carbohydrate loading + high-protein pre-op diet"],
      post: [
        "Day 0–1: clear liquids when haemodynamically stable",
        "Day 2–3: soft diet with focus on protein and calcium",
        "Week 1+: HIGH-PROTEIN diet (1.5–2.0 g/kg/day) — critical for bone matrix formation",
        "Calcium: 1200 mg/day — milk, yoghurt, omena (small fish), dark greens",
        "Vitamin D3: 800–2000 IU/day — essential for calcium absorption and bone healing",
        "Vitamin C: 500–1000 mg/day — collagen synthesis for callus formation",
        "Zinc: 15–25 mg/day — bone healing enzyme cofactor",
        "Omega-3 fatty acids: anti-inflammatory; fish 3×/week",
        "Avoid: alcohol (impairs bone healing), excessive caffeine, smoking"
      ],
      keyNutrients: "Calcium, Vitamin D3, Vitamin C, Zinc, Protein (2 g/kg/day)"
    },
    research: [
      { title: "Functional outcomes of the knee after retrograde and antegrade intramedullary nailing for femoral shaft fractures", journal: "Annals of African Surgery", year: 2022, url: "https://www.annalsofafricansurgery.com/10-2", note: "Njoroge, Mwangi, Lelei — Kenyan data on femoral nailing outcomes." },
      { title: "Pre- and Post-Surgical Nutrition for Preservation of Muscle Mass Following Orthopedic Surgery", journal: "PMC / Nutrients", year: 2021, url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8156786/", note: "EAAs post-surgery; protein targets; oral nutritional supplements reduce hospitalisation cost by 12.2%." }
    ]
  },
  {
    id: 7, code: "TUBAL", name: "Tubal Ligation", specialty: "Gynaecology",
    color: "#fbeaf0", accent: "#72243e",
    overview: "Permanent contraception via surgical occlusion of the fallopian tubes. Methods include Pomeroy technique (cut and tie), Filshie clips, bipolar coagulation, or salpingectomy. Usually performed laparoscopically or minilaparotomy, often postpartum (within 48h of delivery) or interval (6+ weeks postpartum). A key family planning procedure in Kenya's public health system.",
    indications: ["Elective permanent contraception", "Postpartum sterilisation (during C-Section or shortly after)", "Interval sterilisation", "Medical contraindications to pregnancy"],
    procedure: "Laparoscopic: 2 ports → identification of tubes → clip/coagulation/partial resection. Minilaparotomy: small suprapubic incision → tube identification → Pomeroy ligation and resection. Duration 15–30 minutes. Can be combined with C-Section (no additional incision).",
    complications: ["Failure rate 0.5–1% (varies by method)", "Ectopic pregnancy if failure occurs", "Anaesthetic complications", "Bowel/vessel injury (laparoscopic)", "Regret (irreversibility requires complex reversal)"],
    diet: {
      label: "Modified C-Section Protocol (Minor Abdominal)",
      badge: "⚠️ Modified",
      badgeColor: "#72243e",
      pre: ["Standard ERAS fasting: no food 6h, clear liquids up to 2h pre-op", "Carbohydrate loading if standalone procedure", "Normal nutrition — minimal nutritional intervention needed for this minor procedure"],
      post: [
        "Day 0: clear liquids 2–4h post-procedure (very short procedure)",
        "Day 1: normal diet tolerated by most patients",
        "Avoid heavy meals and gas-forming foods for 24–48h (laparoscopic CO₂)",
        "High-protein diet for 1 week for wound healing",
        "Hydrate well: 2 L water/day",
        "If postpartum: breastfeeding nutrition protocol (see C-Section)",
        "No specific long-term dietary modification required"
      ],
      keyNutrients: "Protein, Iron (if postpartum), Hydration"
    },
    research: [
      { title: "Family planning surgery complication rates in Kenya — KHSSP reports", journal: "Kenya Health Sector Strategic Plan", year: 2023, url: "https://pmc.ncbi.nlm.nih.gov/", note: "Postpartum tubal ligation widely performed in Kenya; complication rates low in skilled hands." }
    ]
  },
  {
    id: 8, code: "CHOLE", name: "Cholecystectomy", specialty: "General Surgery",
    color: "#faeeda", accent: "#854f0b",
    overview: "Removal of the gallbladder, usually for symptomatic gallstones (cholelithiasis) or cholecystitis. ~1 million performed annually in the US. Laparoscopic cholecystectomy (LC) is the gold standard worldwide. Robotic use increasing (0.7%/year, JAMA Surgery 2024). A key procedure in East African hospitals as diet patterns shift toward higher fat intake.",
    indications: ["Symptomatic gallstones / biliary colic", "Acute cholecystitis", "Chronic cholecystitis", "Choledocholithiasis (with common bile duct exploration)", "Gallbladder polyps >10mm", "Gallbladder cancer (early)"],
    procedure: "Laparoscopic: 4-port technique → dissection of Calot's triangle → critical view of safety (CVS) essential → clip and divide cystic duct and artery → specimen extraction → closure. Duration 45–90 min. Open: right subcostal (Kocher) incision → same steps. Conversion rate: 1.7% (robotic) vs 3.0% (laparoscopic).",
    complications: ["Bile duct injury (most feared: 0.3–0.5%)", "Bile leak", "Haemorrhage", "Post-cholecystectomy syndrome", "Port-site hernia", "Retained common bile duct stone"],
    diet: {
      label: "Fat-Restricted Progressive Protocol",
      badge: "✅ Custom",
      badgeColor: "#854f0b",
      pre: [
        "2–4 weeks pre-op: LOW-FAT diet (≤30g fat/day) to reduce gallbladder contractility and inflammation",
        "Avoid: fried foods, fatty meats, full-fat dairy, butter, oil-heavy cooking",
        "Small frequent meals to avoid large gallbladder contractions",
        "Carbohydrate loading the night before and 2h pre-op"
      ],
      post: [
        "Day 0–1: clear liquids; no fat whatsoever",
        "Day 2–3: very-low-fat soft diet — boiled rice, boiled vegetables, lean fish, bananas",
        "Week 1: <10g fat/day; introduce small amounts of healthy fats gradually",
        "Week 2–4: LOW-FAT diet (<30g fat/day); avoid fried foods entirely",
        "Month 2+: gradually reintroduce normal fats; most patients tolerate normal diet by 4–8 weeks",
        "Some patients develop 'post-cholecystectomy syndrome' — diarrhoea after fatty meals; continue low-fat",
        "HIGH-FIBRE: helps compensate for reduced bile concentration affecting fat digestion",
        "Avoid: alcohol, carbonated drinks, spicy foods initially"
      ],
      keyNutrients: "Low fat, Fibre, Vitamin ADEK (fat-soluble — monitor if fat absorption affected), Protein"
    },
    research: [
      { title: "Robot-assisted Procedures in General Surgery: Cholecystectomy, Inguinal and Ventral Hernia Repairs", journal: "NCBI Bookshelf / VA Evidence Synthesis", year: 2020, url: "https://www.ncbi.nlm.nih.gov/books/NBK570695/", note: "Systematic review; robotic shows lower conversion to open; cost-effectiveness debated." },
      { title: "Complications in simultaneous laparoscopic cholecystectomy and hernia repair: meta-analysis", journal: "ScienceDirect / Heliyon", year: 2024, url: "https://www.sciencedirect.com/science/article/pii/S2405844025019656", note: "598 patients; combining procedures safe if gallbladder intact; mesh infection risk when combined." }
    ]
  },
  {
    id: 9, code: "PROSTA", name: "Prostatectomy", specialty: "Urology",
    color: "#e6f1fb", accent: "#0c447c",
    overview: "Surgical removal of part (simple) or all (radical) of the prostate gland. Radical prostatectomy (RP) treats localised prostate cancer. Simple prostatectomy treats benign prostatic hyperplasia (BPH). Approaches: open retropubic, laparoscopic, or robotic (RARP — da Vinci). RARP is standard in well-resourced settings; Aga Khan Hospital Nairobi offers robotic prostatectomy in Kenya. Prostate cancer is increasingly recognised in East Africa.",
    indications: ["Localised prostate cancer (radical)", "Benign prostatic hyperplasia with urinary obstruction (simple)", "Failed conservative/medical management of BPH"],
    procedure: "Retropubic RP: lower midline incision → pelvic lymph node dissection → prostate dissection → neurovascular bundle preservation (nerve-sparing) → vesicourethral anastomosis. Robotic: 6 ports → pneumoperitoneum → same steps with robotic precision. Duration 2–4 hours.",
    complications: ["Urinary incontinence (temporary in most, permanent in ~5–10%)", "Erectile dysfunction (nerve-sparing reduces risk)", "Anastomotic leak / stricture", "DVT/PE", "Lymphocele", "Biochemical recurrence of cancer"],
    diet: {
      label: "Modified C-Section Protocol + Prostate-Specific Nutrients",
      badge: "⚠️ Modified",
      badgeColor: "#0c447c",
      pre: ["ERAS carbohydrate loading pre-op", "Prostate-healthy diet: tomatoes (lycopene), green tea, cruciferous vegetables", "Reduce red/processed meat, high-fat dairy pre-op"],
      post: [
        "Day 0–1: clear liquids; catheter in situ",
        "Day 2–3: soft diet; avoid straining (bowel movements risk anastomosis)",
        "HIGH-FIBRE diet from day 3 to prevent constipation and straining",
        "Stool softeners routinely recommended",
        "Fluid intake: 2–3 L/day to flush urinary system",
        "Anti-inflammatory diet long-term: berries, turmeric, green tea, fish",
        "Lycopene-rich foods: tomatoes (cooked tomatoes better absorbed)",
        "Limit red meat, processed foods, high-fat dairy",
        "Avoid alcohol during catheter period"
      ],
      keyNutrients: "Lycopene, Selenium, Zinc, Omega-3, Fibre, Vitamin E"
    },
    research: [
      { title: "Low Cost Robotic Radical Prostatectomy in Kenya — Aga Khan University Hospital", journal: "Lyfboat / AKU Hospital", year: 2024, url: "https://www.lyfboat.com/hospitals/prostatectomy-hospitals-and-costs-in-kenya/", note: "AKUH Nairobi offers robotic prostatectomy — most advanced urology in East Africa." },
      { title: "Prostate cancer surgery outcomes Kenya — Annals of African Surgery database", journal: "Annals of African Surgery", year: 2022, url: "https://www.annalsofafricansurgery.com/", note: "Increasing prostate cancer burden in SSA; surgical outcomes data emerging." }
    ]
  },
  {
    id: 10, code: "THYROID", name: "Thyroidectomy", specialty: "Endocrine Surgery",
    color: "#eaf3de", accent: "#27500a",
    overview: "Removal of part (lobectomy, subtotal) or all (total thyroidectomy) of the thyroid gland. Goitre (iodine deficiency) remains prevalent in East African highland areas. Kenyan surgeons at AAS have published on drain use post-thyroidectomy and anaesthesia approaches. Thyroid cancer (papillary most common) is increasing in Africa. Hyperparathyroidism may require concurrent parathyroidectomy.",
    indications: ["Thyroid cancer", "Large goitre causing compression symptoms", "Hyperthyroidism (Graves' disease) refractory to medical treatment", "Toxic multinodular goitre", "Thyroid nodule with indeterminate/suspicious biopsy"],
    procedure: "Collar incision (Kocher) → subplatysmal flaps → identification and preservation of recurrent laryngeal nerves (RLN) and parathyroid glands → thyroid dissection → haemostasis → drain (controversial) → closure. Intraoperative nerve monitoring (IONM) is standard in high-resource settings. Duration 1–3 hours.",
    complications: ["RLN injury → hoarseness or voice change", "Hypoparathyroidism → hypocalcaemia (most common complication)", "Haematoma (can be life-threatening — airway compression)", "Hypothyroidism (requires lifelong levothyroxine)", "Thyroid storm (rare, hyperthyroid patients)"],
    diet: {
      label: "Modified C-Section Protocol + Calcium Protocol",
      badge: "⚠️ Modified",
      badgeColor: "#27500a",
      pre: ["Normal diet up to 6h pre-op", "Iodine restriction 2 weeks pre-op for Graves' disease (Lugol's iodine given)", "High-calcium diet pre-op to load stores (parathyroid at risk)"],
      post: [
        "Day 0: clear liquids; soft swallowing initially if neck discomfort",
        "Day 1: soft diet — avoid hard foods that require vigorous swallowing",
        "CRITICAL: HIGH-CALCIUM diet post-op — 1200–1500 mg/day",
        "Milk, yoghurt, omena, fortified foods; calcium supplements if diet insufficient",
        "Vitamin D3: 800–2000 IU/day — essential for calcium absorption",
        "Monitor for hypocalcaemia: tingling lips/fingers, muscle cramps (Chvostek's sign)",
        "Lifelong levothyroxine (if total thyroidectomy) — take on empty stomach 30–60 min before food",
        "Avoid goitrogens in large amounts: raw cabbage, cassava leaves (soak/cook thoroughly)",
        "Iodine-adequate diet: iodised salt, seafood (if cancer-free)"
      ],
      keyNutrients: "Calcium, Vitamin D3, Iodine (if cancer-free), Selenium (thyroid function)"
    },
    research: [
      { title: "Drains after thyroidectomy for benign thyroid disorders: associated with more pain, wound infection and prolonged stay", journal: "Annals of African Surgery", year: 2022, url: "https://www.annalsofafricansurgery.com/10-2", note: "Kenyan data on drain use; recommends against routine drains in uncomplicated thyroidectomy." },
      { title: "The role of infiltrative local anaesthesia in thyroidectomy", journal: "Annals of African Surgery (Ojuka, Saidi, Rere)", year: 2022, url: "https://www.annalsofafricansurgery.com/10-2", note: "Nairobi surgeons — pain management in thyroidectomy; local anaesthesia effectiveness." }
    ]
  },
  {
    id: 11, code: "TKR", name: "Knee Replacement (TKR)", specialty: "Orthopaedics",
    color: "#e1f5ee", accent: "#085041",
    overview: "Total knee replacement (TKR) resurfaces the entire knee joint. Primary indication: end-stage osteoarthritis. Oxford Knee Scores improve from ~15 to ~45 post-TKR in SSA studies. Cemented implants remain the standard; semi-constrained implants used more in Africa due to advanced valgus deformity at presentation (patients delay due to financial constraints). A growing procedure in Kenya — both at KNH and private hospitals.",
    indications: ["End-stage osteoarthritis", "Rheumatoid arthritis with joint destruction", "Post-traumatic arthritis", "Failed previous knee surgery", "Osteonecrosis"],
    procedure: "Medial parapatellar approach → bone cuts (femur, tibia, patella) using cutting guides → trial components → cementation → component placement → closure over drain. Computer-assisted surgery and robotics emerging. Duration 1.5–2.5 hours. Tourniquet used.",
    complications: ["Infection (deep infection 1.6% in SSA) — most serious", "DVT/PE (high risk)", "Aseptic loosening", "Instability", "Periprosthetic fracture", "Stiffness", "34% loss to follow-up at 6 months in Kenya (Kingori & Gakuu)"],
    diet: {
      label: "High-Protein Musculoskeletal Recovery Protocol",
      badge: "✅ Custom",
      badgeColor: "#085041",
      pre: [
        "2 weeks pre-op: HIGH-PROTEIN diet (1.5 g/kg/day) to build muscle mass",
        "Optimise weight: excess BMI increases implant stress",
        "Calcium 1200 mg/day + Vitamin D3 800 IU/day",
        "Iron supplementation if anaemic (reduces transfusion need)",
        "ERAS carbohydrate loading protocol night before and 2h pre-op"
      ],
      post: [
        "Day 0: clear liquids when alert; early mobilisation with physio",
        "Day 1: full diet; protein supplementation crucial",
        "HIGH-PROTEIN: 2.0 g/kg/day — lean meat, fish, eggs, legumes, dairy",
        "Oral nutritional supplements (ONS) if diet insufficient — reduce hospitalisation by 12.2%",
        "Anti-inflammatory foods: omega-3 (fish, flaxseed), turmeric, ginger",
        "Calcium + Vitamin D3 continued 6–12 months post-op",
        "Hydration: 2–3 L/day; supports joint fluid production",
        "Avoid: alcohol, smoking (impair bone integration and wound healing)",
        "Weight management diet long-term to protect implant longevity"
      ],
      keyNutrients: "Protein (2 g/kg/day), Calcium, Vitamin D, Omega-3, Collagen precursors (Vitamin C)"
    },
    research: [
      { title: "Total joint replacement in sub-Saharan Africa: systematic review", journal: "PMC / Bone & Joint Open", year: 2019, url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC6535807/", note: "606 THRs and 763 TKRs; outcomes comparable to high-income countries; 34% loss to follow-up in Kenya; deep infection 1.6% for TKR." },
      { title: "Joint replacement surgery in Ghana (West Africa): observational study", journal: "PMC", year: 2019, url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC6470119/", note: "Semi-constrained implants used more in SSA due to advanced valgus deformity at presentation." },
      { title: "Pre- and Post-Surgical Nutrition for Preservation of Muscle Mass Following Orthopedic Surgery", journal: "PMC / Nutrients", year: 2021, url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8156786/", note: "Protein 2 g/kg/day; EAA supplementation; ONS reduces cost and complications in orthopaedic patients." }
    ]
  },
  {
    id: 12, code: "THR", name: "Hip Replacement (THR)", specialty: "Orthopaedics",
    color: "#e1f5ee", accent: "#04342c",
    overview: "Total hip replacement resurfaces the femoral head and acetabulum. In Sub-Saharan Africa, avascular necrosis (AVN) of the femoral head is the most common indication for THR (vs osteoarthritis in high-income countries), often secondary to sickle cell disease, alcohol use, corticosteroids, or HIV-related conditions. Harris Hip Scores improve from ~28 to ~85 post-THR in SSA studies. Dislocation rate 1.6%, deep infection rate 0.5%.",
    indications: ["Avascular necrosis (AVN) — most common in SSA", "Osteoarthritis", "Femoral neck fracture (elderly)", "Rheumatoid arthritis", "Failed previous hip surgery"],
    procedure: "Posterior or anterolateral approach → femoral neck osteotomy → acetabular reaming → cup placement (cemented/press-fit) → femoral stem insertion → head and liner assembly → reduction → layered closure. Duration 1.5–3 hours.",
    complications: ["Dislocation (1.6% in SSA)", "Deep infection (0.5% in SSA)", "DVT/PE", "Aseptic loosening", "Periprosthetic fracture", "Leg length discrepancy", "Sciatic nerve injury"],
    diet: {
      label: "Modified C-Section Protocol + Bone Healing",
      badge: "⚠️ Modified",
      badgeColor: "#04342c",
      pre: ["Same as TKR: high-protein, calcium, Vitamin D pre-op optimisation", "Sickle cell patients: ensure well-hydrated, avoid triggers pre-operatively", "ERAS carbohydrate loading"],
      post: [
        "Similar to TKR post-op protocol",
        "HIGH-PROTEIN: 2.0 g/kg/day",
        "Calcium 1200 mg + Vitamin D3 800–2000 IU/day",
        "Anti-inflammatory diet; omega-3 fatty acids",
        "Sickle cell patients: HIGH fluid intake (3 L/day) to prevent crisis",
        "Avoid alcohol — major cause of AVN; cessation mandatory",
        "Iron-rich diet if sickle cell/anaemia complicates recovery",
        "Long-term: maintain healthy weight to reduce prosthesis wear"
      ],
      keyNutrients: "Protein, Calcium, Vitamin D, Iron (if sickle cell), Hydration"
    },
    research: [
      { title: "Total joint replacement in sub-Saharan Africa: systematic review", journal: "PMC", year: 2019, url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC6535807/", note: "AVN most common indication for THR in SSA; comparable outcomes to high-income settings. Sickle cell and HIV prevalent comorbidities (HIV up to 33%)." }
    ]
  },
  {
    id: 13, code: "MAST", name: "Mastectomy", specialty: "Surgical Oncology",
    color: "#fcebeb", accent: "#a32d2d",
    overview: "Surgical removal of the breast, primarily for breast cancer treatment. In Kenya and Africa, modified radical mastectomy (MRM) is performed in 64–67% of cases (vs breast-conserving surgery 15–26%) due to advanced disease at presentation (stages III–IV). The five-year survival rate does not exceed 60% in any African LMIC. Fear of mastectomy causes significant treatment delays in sub-Saharan Africa. Dr Miriam Mutebi (AKU Nairobi) is a leading advocate for improving surgical cancer care.",
    indications: ["Breast cancer (most common)", "BRCA1/2 mutation carrier (prophylactic mastectomy)", "Locally advanced breast cancer", "Inflammatory breast cancer", "Male breast cancer"],
    procedure: "MRM: elliptical incision around breast → skin flaps raised → breast and axillary lymph node dissection (ALND) → haemostasis → drain placement → closure. Skin-sparing and nipple-sparing mastectomy with reconstruction emerging in high-resource settings. Duration 2–4 hours.",
    complications: ["Seroma (most common)", "Lymphoedema of arm (after ALND)", "Wound infection", "Flap necrosis", "Phantom breast pain", "Psychosocial impact — depression, body image, stigma (significant in SSA)"],
    diet: {
      label: "Modified C-Section Protocol + Oncology Nutrition",
      badge: "⚠️ Modified",
      badgeColor: "#a32d2d",
      pre: [
        "Correct malnutrition pre-op — common in advanced cancer",
        "Immunonutrition 5–7 days pre-op (arginine, omega-3, antioxidants) — reduces infectious complications",
        "ERAS carbohydrate loading",
        "Iron supplementation if anaemic"
      ],
      post: [
        "Day 0: clear liquids 4h post-op",
        "Day 1: light diet — low fat, easy-to-digest; manage nausea from anaesthesia",
        "Week 1–2: full diet with emphasis on anti-cancer, anti-inflammatory foods",
        "HIGH-PROTEIN: 1.5–2.0 g/kg/day — essential if chemotherapy follows",
        "Anti-cancer diet: berries, cruciferous vegetables (broccoli, sukuma wiki), tomatoes, green tea",
        "Omega-3: fish 3×/week; reduces inflammation and supports immune recovery",
        "Calcium + Vitamin D: if hormone therapy (aromatase inhibitors) planned — prevents bone loss",
        "AVOID: alcohol (increases recurrence risk), processed meats, excessive red meat",
        "Lymphoedema management: avoid high-sodium foods (worsen swelling)"
      ],
      keyNutrients: "Protein, Omega-3, Antioxidants (Vit C, E, Beta-carotene), Calcium, Vitamin D"
    },
    research: [
      { title: "Surgical management of breast cancer in Africa: a continent-wide review", journal: "JCO Global Oncology", year: 2017, url: "https://ascopubs.org/doi/10.1200/JGO.2016.003095", note: "MRM >50–90% of cases; breast-conserving surgery rare; stage III–IV most common at presentation." },
      { title: "Real-world challenges for breast cancer patients in sub-Saharan Africa: Ghana, Kenya, Nigeria", journal: "PMC / BMJ Open", year: 2021, url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC7929861/", note: "862 patients; 64–67% underwent mastectomy; turnaround to surgery 1–5 months; 30–32% paid OOP in Kenya." },
      { title: "Quality of breast cancer surgery in Africa — UICC / Mutebi (AKU Nairobi)", journal: "UICC", year: 2025, url: "https://www.uicc.org/news-and-updates/news/25-m4-importance-providing-quality-breast-cancer-surgery-africa", note: "Dr Miriam Mutebi: most cancer surgeries by general surgeons; need for specialised oncosurgery training." },
      { title: "Post-mastectomy quality of life in Africa: scoping review", journal: "PMC", year: 2024, url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC12345023/", note: "Physical, psychological, social and sexual health challenges post-mastectomy in African women." }
    ]
  },
  {
    id: 14, code: "MYOM", name: "Myomectomy", specialty: "Gynaecology",
    color: "#fbeaf0", accent: "#4b1528",
    overview: "Surgical removal of uterine fibroids (myomas) while preserving the uterus. Extremely high prevalence in Kenya and sub-Saharan Africa — fibroids affect up to 70–80% of Black women by age 50. Uterine fibroids are the single most common indication for hysterectomy in Kenya. Myomectomy is preferred in women wishing to preserve fertility. Approaches: open (laparotomy), laparoscopic, hysteroscopic (submucosal), or robotic.",
    indications: ["Symptomatic fibroids with heavy menstrual bleeding", "Pelvic pressure/pain from large fibroids", "Fertility-preserving surgery (vs hysterectomy)", "Recurrent pregnancy loss due to fibroids", "Fibroids causing urinary/bowel symptoms"],
    procedure: "Open: uterine incision(s) over fibroid(s) → enucleation → haemostatic suturing of uterus → abdominal closure. Laparoscopic: ports → morcellation (controversial) or mini-laparotomy extraction. Hysteroscopic: submucosal fibroids resected via hysteroscope (no abdominal incision). Duration 1–4 hours depending on number/size.",
    complications: ["Haemorrhage (risk of hysterectomy if uncontrolled)", "Adhesion formation (affects fertility)", "Fibroid recurrence (up to 50% over 10 years)", "Uterine scar rupture in subsequent pregnancy"],
    diet: {
      label: "Modified C-Section Protocol + Anti-Fibroid Nutrition",
      badge: "⚠️ Modified",
      badgeColor: "#4b1528",
      pre: [
        "Iron supplementation: fibroids cause heavy periods → iron-deficiency anaemia in most patients",
        "GnRH agonists may be given pre-op to shrink fibroids and reduce blood loss",
        "Iron-rich foods: red meat, lentils, spinach, dark greens + Vitamin C for absorption",
        "ERAS carbohydrate loading pre-op"
      ],
      post: [
        "Day 0–1: clear liquids → progress as for laparotomy",
        "HIGH-IRON diet: essential post-op — heavy perioperative blood loss",
        "Vitamin C with every iron-rich meal to enhance absorption",
        "HIGH-PROTEIN: 1.5 g/kg/day for uterine repair",
        "Calcium + Vitamin D (GnRH agonist-induced bone loss if used)",
        "Anti-oestrogen dietary approach (long-term fibroid prevention):",
        "→ Cruciferous vegetables (broccoli, kale, sukuma wiki) — support oestrogen metabolism",
        "→ Reduce red meat, alcohol, high-fat dairy (pro-oestrogenic)",
        "→ Flaxseed, soy (phytoestrogens — weak; modest benefit)",
        "→ Vitamin D deficiency linked to fibroid risk — supplementation recommended"
      ],
      keyNutrients: "Iron, Vitamin C, Calcium, Vitamin D, Protein"
    },
    research: [
      { title: "Uterine fibroid burden Kenya / SSA — high prevalence data", journal: "Multiple African gynaecological studies", year: 2023, url: "https://pmc.ncbi.nlm.nih.gov/", note: "Fibroids affect up to 70–80% of Black women; most common indication for gynaecological surgery in Kenya." },
      { title: "ERAS for gynaecological surgery including myomectomy", journal: "ESPEN Clinical Nutrition / ESPEN guideline", year: 2021, url: "https://www.espen.org/files/ESPEN_practical_guideline_Clinical_nutrition_in_surgery.pdf", note: "ERAS protocols validated for gynaecological surgery; early feeding, immunonutrition pre-op." }
    ]
  },
  {
    id: 15, code: "CARDIAC", name: "Cardiac Surgery", specialty: "Cardiac Surgery",
    color: "#fcebeb", accent: "#791f1f",
    overview: "Open-heart and major cardiac procedures including valve repair/replacement, coronary artery bypass grafting (CABG), and congenital heart disease correction. Sub-Saharan Africa has severely limited cardiac surgery capacity — Kenya's Tenwek Hospital is a landmark local programme that achieved surgical independence during COVID-19 when international missions were suspended. Rheumatic heart disease (RHD) dominates in Africa vs atherosclerotic disease in the West. Estimated unmet surgical need: millions across SSA.",
    indications: ["Rheumatic heart disease with valve stenosis/regurgitation", "Congenital heart defects (VSD, ASD, TOF)", "Coronary artery disease requiring CABG", "Cardiac tumours (myxoma)", "Aortic aneurysm", "Endocarditis with valve destruction"],
    procedure: "Median sternotomy → cardiopulmonary bypass (CPB) established → cardiac arrest (cardioplegia) → specific repair (valve replacement with prosthetic/biological valve; CABG using saphenous vein/internal mammary artery) → weaning from CPB → chest closure with sternal wires. Duration 3–8 hours. ICU admission mandatory post-op.",
    complications: ["Low cardiac output syndrome", "Arrhythmias (AF most common post-op)", "Stroke", "Bleeding / tamponade", "Acute kidney injury", "Sternal wound infection / mediastinitis", "Prolonged ventilation", "Death (mortality higher in SSA than high-income settings)"],
    diet: {
      label: "Modified C-Section + Cardiac-Specific Protocol",
      badge: "⚠️ Modified",
      badgeColor: "#791f1f",
      pre: [
        "Cardiac diet 4–6 weeks pre-op: low sodium (<2g/day), low saturated fat, heart-healthy",
        "Correct malnutrition — common in RHD patients with cardiac cachexia",
        "Correct anaemia: iron supplementation",
        "No solid food 6h, clear liquids up to 2h pre-op",
        "Vitamin K restriction if on warfarin (bridging protocol)"
      ],
      post: [
        "Day 0: NBM — intubated/ventilated; enteral nutrition via NGT if prolonged ventilation",
        "Extubation day 1–2: clear liquids → progress to soft cardiac diet",
        "LOW SODIUM: <2g/day; reduces fluid overload and cardiac strain",
        "LOW SATURATED FAT: lean meats, fish, plant oils; avoid butter, ghee, coconut oil",
        "HIGH OMEGA-3: fish 3×/week; oily fish (sardines, mackerel) — anti-arrhythmic",
        "Potassium-rich foods: banana, avocado, sweet potato (monitor if on diuretics)",
        "Warfarin patients: CONSISTENT Vitamin K intake (not low — consistent); avoid alcohol",
        "High-protein for sternal wound healing: 1.5–2 g/kg/day",
        "Fluid restriction if heart failure: typically 1.5 L/day",
        "Cardiac rehabilitation diet: Mediterranean-style long-term"
      ],
      keyNutrients: "Low sodium, Omega-3, Potassium, Magnesium, Protein, Vitamin K management"
    },
    research: [
      { title: "Cardiac Surgery in Sub-Saharan Africa: Anthills of the Savannah", journal: "JACC: Advances", year: 2024, url: "https://www.jacc.org/doi/10.1016/j.jacadv.2024.101223", note: "Tenwek Hospital Kenya achieved surgical independence during COVID-19. Rheumatic heart disease dominates; overseas transfers still preponderant. Mentorship models (Cape Town/Maputo; Team Heart Rwanda) key to building local capacity." },
      { title: "Access to Cardiac Surgery Services in Sub-Saharan Africa: Quo Vadis?", journal: "PubMed", year: 2020, url: "https://pubmed.ncbi.nlm.nih.gov/32356285/", note: "Critical review of capacity gaps; call for self-sufficiency models and local training." },
      { title: "Access to cardiac surgery in sub-Saharan Africa", journal: "PubMed", year: 2015, url: "https://pubmed.ncbi.nlm.nih.gov/25706083/", note: "Foundational paper establishing scale of the access gap in SSA cardiac surgery." }
    ]
  }
];

const specialtyColors = {
  "Obstetrics": "#0f6e56",
  "General Surgery": "#185fa5",
  "Gynaecology": "#993556",
  "Orthopaedics": "#3b6d11",
  "Urology": "#0c447c",
  "Endocrine Surgery": "#27500a",
  "Surgical Oncology": "#a32d2d",
  "Cardiac Surgery": "#791f1f",
};

export default function SurgeryRef() {
  const [selected, setSelected] = useState(null);
  const [tab, setTab] = useState("overview");
  const [search, setSearch] = useState("");

  const filtered = surgeries.filter(s =>
    s.name.toLowerCase().includes(search.toLowerCase()) ||
    s.specialty.toLowerCase().includes(search.toLowerCase()) ||
    s.code.toLowerCase().includes(search.toLowerCase())
  );

  const tabs = ["overview", "procedure", "diet", "research"];

  return (
    <div style={{fontFamily: "var(--font-sans)", padding: "1rem 0"}}>
      <h2 style={{position: "absolute", opacity: 0, pointerEvents: "none"}}>15 Surgical Procedures Deep Reference Guide</h2>

      {!selected ? (
        <>
          <div style={{display:"flex", gap:8, marginBottom:16, alignItems:"center"}}>
            <input
              type="text" placeholder="Search by name or specialty..."
              value={search} onChange={e => setSearch(e.target.value)}
              style={{flex:1, maxWidth:340, padding:"6px 10px", fontSize:14, borderRadius:8, border:"0.5px solid var(--color-border-secondary)"}}
            />
            <span style={{fontSize:12, color:"var(--color-text-secondary)"}}>{filtered.length} procedures</span>
          </div>

          <div style={{display:"grid", gridTemplateColumns:"repeat(auto-fill, minmax(260px, 1fr))", gap:10}}>
            {filtered.map(sur => (
              <div key={sur.id}
                onClick={() => { setSelected(sur); setTab("overview"); }}
                style={{
                  background: sur.color, border: `1.5px solid ${sur.accent}33`,
                  borderRadius: 12, padding:"14px 16px", cursor:"pointer",
                  transition:"transform 0.1s", userSelect:"none"
                }}
                onMouseEnter={e => e.currentTarget.style.transform="scale(1.01)"}
                onMouseLeave={e => e.currentTarget.style.transform="scale(1)"}
              >
                <div style={{display:"flex", justifyContent:"space-between", alignItems:"flex-start", marginBottom:6}}>
                  <span style={{fontSize:11, fontWeight:500, color: sur.accent, background: sur.accent+"20", padding:"2px 8px", borderRadius:20}}>{sur.specialty}</span>
                  <span style={{fontSize:11, color:"var(--color-text-secondary)", fontWeight:500}}>#{sur.id}</span>
                </div>
                <div style={{fontSize:15, fontWeight:500, color:"var(--color-text-primary)", marginBottom:4}}>{sur.name}</div>
                <div style={{fontSize:12, color:"var(--color-text-secondary)", marginBottom:8}}>{sur.code}</div>
                <div style={{fontSize:11, padding:"3px 8px", borderRadius:6, display:"inline-block",
                  background: sur.diet.badge.includes("✅") ? "#d1fae520" : "#f3f4f620",
                  color: sur.diet.badge.includes("✅") ? sur.accent : "#888",
                  border: `0.5px solid ${sur.diet.badge.includes("✅") ? sur.accent+"40" : "#ddd"}`
                }}>{sur.diet.badge} {sur.diet.label}</div>
              </div>
            ))}
          </div>
          <div style={{marginTop:16, fontSize:12, color:"var(--color-text-secondary)"}}>
            Tap any surgery card to view deep details — clinical overview, procedure, diet protocol, and linked research papers.
          </div>
        </>
      ) : (
        <div>
          <button onClick={() => setSelected(null)}
            style={{marginBottom:14, fontSize:13, padding:"5px 12px", borderRadius:8, border:"0.5px solid var(--color-border-secondary)", background:"transparent", cursor:"pointer", color:"var(--color-text-secondary)"}}>
            ← Back to all surgeries
          </button>

          <div style={{background: selected.color, borderRadius:12, padding:"16px 20px", marginBottom:16, borderLeft: `4px solid ${selected.accent}`}}>
            <div style={{display:"flex", justifyContent:"space-between", alignItems:"flex-start", flexWrap:"wrap", gap:8}}>
              <div>
                <div style={{fontSize:11, color: selected.accent, fontWeight:500, marginBottom:4}}>{selected.specialty} — #{selected.id}</div>
                <div style={{fontSize:20, fontWeight:500, color:"var(--color-text-primary)"}}>{selected.name}</div>
                <div style={{fontSize:13, color:"var(--color-text-secondary)"}}>{selected.code}</div>
              </div>
              <div style={{fontSize:11, padding:"4px 10px", borderRadius:8,
                background: selected.diet.badge.includes("✅") ? selected.accent+"20" : "#f0f0f020",
                color: selected.diet.badge.includes("✅") ? selected.accent : "#888",
                border:`0.5px solid ${selected.accent}40`}}>
                {selected.diet.badge} {selected.diet.label}
              </div>
            </div>
          </div>

          <div style={{display:"flex", gap:6, marginBottom:16, flexWrap:"wrap"}}>
            {tabs.map(t => (
              <button key={t} onClick={() => setTab(t)}
                style={{
                  padding:"6px 14px", borderRadius:20, fontSize:13, cursor:"pointer",
                  fontWeight: tab === t ? 500 : 400,
                  background: tab === t ? selected.accent : "transparent",
                  color: tab === t ? "#fff" : "var(--color-text-secondary)",
                  border: `0.5px solid ${tab === t ? selected.accent : "var(--color-border-secondary)"}`
                }}>
                {t.charAt(0).toUpperCase() + t.slice(1)}
              </button>
            ))}
          </div>

          {tab === "overview" && (
            <div>
              <p style={{fontSize:14, lineHeight:1.7, color:"var(--color-text-primary)", marginBottom:16}}>{selected.overview}</p>

              <div style={{display:"grid", gridTemplateColumns:"1fr 1fr", gap:12}}>
                <div style={{background:"var(--color-background-secondary)", borderRadius:10, padding:"12px 16px"}}>
                  <div style={{fontSize:12, fontWeight:500, color:"var(--color-text-secondary)", marginBottom:8, textTransform:"uppercase", letterSpacing:"0.5px"}}>Indications</div>
                  {selected.indications.map((ind, i) => (
                    <div key={i} style={{fontSize:13, color:"var(--color-text-primary)", padding:"3px 0", borderBottom:"0.5px solid var(--color-border-tertiary)", display:"flex", gap:6}}>
                      <span style={{color: selected.accent, fontSize:12}}>▸</span> {ind}
                    </div>
                  ))}
                </div>
                <div style={{background:"var(--color-background-secondary)", borderRadius:10, padding:"12px 16px"}}>
                  <div style={{fontSize:12, fontWeight:500, color:"var(--color-text-secondary)", marginBottom:8, textTransform:"uppercase", letterSpacing:"0.5px"}}>Complications</div>
                  {selected.complications.map((c, i) => (
                    <div key={i} style={{fontSize:13, color:"var(--color-text-primary)", padding:"3px 0", borderBottom:"0.5px solid var(--color-border-tertiary)", display:"flex", gap:6}}>
                      <span style={{color:"#c0392b", fontSize:12}}>!</span> {c}
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {tab === "procedure" && (
            <div style={{background:"var(--color-background-secondary)", borderRadius:10, padding:"16px 20px"}}>
              <div style={{fontSize:12, fontWeight:500, color:"var(--color-text-secondary)", marginBottom:10, textTransform:"uppercase", letterSpacing:"0.5px"}}>Surgical Technique</div>
              <p style={{fontSize:14, lineHeight:1.7, color:"var(--color-text-primary)", whiteSpace:"pre-wrap"}}>{selected.procedure}</p>
            </div>
          )}

          {tab === "diet" && (
            <div>
              <div style={{background: selected.accent+"15", borderRadius:10, padding:"10px 16px", marginBottom:12, border:`0.5px solid ${selected.accent}40`}}>
                <span style={{fontSize:13, fontWeight:500, color: selected.accent}}>Key Nutrients: </span>
                <span style={{fontSize:13, color:"var(--color-text-primary)"}}>{selected.diet.keyNutrients}</span>
              </div>

              <div style={{display:"grid", gridTemplateColumns:"1fr 1fr", gap:12}}>
                <div style={{background:"var(--color-background-secondary)", borderRadius:10, padding:"12px 16px"}}>
                  <div style={{fontSize:12, fontWeight:500, color:"var(--color-text-secondary)", marginBottom:8, textTransform:"uppercase", letterSpacing:"0.5px"}}>Pre-operative Diet</div>
                  {selected.diet.pre.map((item, i) => (
                    <div key={i} style={{fontSize:12, color:"var(--color-text-primary)", padding:"4px 0", borderBottom:"0.5px solid var(--color-border-tertiary)", lineHeight:1.5, display:"flex", gap:6}}>
                      <span style={{color:"#27ae60", flexShrink:0}}>→</span> {item}
                    </div>
                  ))}
                </div>
                <div style={{background:"var(--color-background-secondary)", borderRadius:10, padding:"12px 16px"}}>
                  <div style={{fontSize:12, fontWeight:500, color:"var(--color-text-secondary)", marginBottom:8, textTransform:"uppercase", letterSpacing:"0.5px"}}>Post-operative Diet</div>
                  {selected.diet.post.map((item, i) => (
                    <div key={i} style={{fontSize:12, color:"var(--color-text-primary)", padding:"4px 0", borderBottom:"0.5px solid var(--color-border-tertiary)", lineHeight:1.5, display:"flex", gap:6}}>
                      <span style={{color: selected.accent, flexShrink:0}}>→</span> {item}
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {tab === "research" && (
            <div>
              <div style={{fontSize:13, color:"var(--color-text-secondary)", marginBottom:12}}>
                Key research papers, guidelines, and studies — click titles to open source links.
              </div>
              {selected.research.map((r, i) => (
                <div key={i} style={{background:"var(--color-background-secondary)", borderRadius:10, padding:"12px 16px", marginBottom:10, borderLeft:`3px solid ${selected.accent}`}}>
                  <a href={r.url} target="_blank" rel="noopener noreferrer"
                    style={{fontSize:14, fontWeight:500, color: selected.accent, textDecoration:"none", display:"block", marginBottom:4}}>
                    {r.title} ↗
                  </a>
                  <div style={{fontSize:12, color:"var(--color-text-secondary)", marginBottom:4}}>
                    {r.journal} · {r.year}
                  </div>
                  <div style={{fontSize:12, color:"var(--color-text-primary)", lineHeight:1.5, fontStyle:"italic"}}>
                    {r.note}
                  </div>
                </div>
              ))}
              <div style={{marginTop:12, padding:"10px 14px", borderRadius:8, background:"var(--color-background-tertiary)", fontSize:12, color:"var(--color-text-secondary)"}}>
                For deeper research searches: PubMed (pubmed.ncbi.nlm.nih.gov) · Cochrane Library · Annals of African Surgery (annalsofafricansurgery.com) · ESPEN Guidelines (espen.org)
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
