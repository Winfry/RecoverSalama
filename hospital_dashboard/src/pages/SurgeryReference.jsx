import { useState } from "react";
import { Search, ArrowLeft, ExternalLink } from "lucide-react";
import { C } from "../theme";

const surgeries = [
  {
    id: 1, code: "C-SECTION", name: "Caesarean Section", specialty: "Obstetrics",
    color: "#E6F7F5", accent: "#0f6e56",
    overview: "The world's most performed major surgery. A baby is delivered through incisions in the abdominal wall (laparotomy) and uterus (hysterotomy). Global rates have risen from ~6% in 1990 to 21% in 2018, exceeding 50% in some middle-income countries. In Kenya it is the single most performed major surgery.",
    indications: ["Labour dystocia / failure to progress", "Foetal distress / non-reassuring CTG", "Malpresentation (breech, transverse)", "Placenta praevia / accreta", "Prior uterine surgery", "Eclampsia / severe pre-eclampsia", "Cord prolapse"],
    procedure: "Pfannenstiel or midline skin incision → rectus sheath incision → bladder flap → lower-segment uterine incision → delivery of neonate → placenta delivery → uterine closure in 1–2 layers → layered abdominal closure. Spinal anaesthesia is gold-standard; GA reserved for emergencies. Duration: 30–60 min.",
    complications: ["Haemorrhage (leading cause of severe maternal morbidity)", "Wound infection / endometritis", "DVT / pulmonary embolism", "Bowel obstruction (OR 2.92× vs vaginal birth)", "Incisional hernia (OR 2.71×)", "Bladder/ureter injury", "Placenta accreta in future pregnancies"],
    diet: { label: "Full Custom Protocol (ERAS-Based)", badge: "Custom", pre: ["Night before: 100 g carbohydrate drink", "2 hours before: 50 g carbohydrate drink", "Immunonutrition 5 days pre-op if at nutrition risk", "High-protein meals: 1.5 g/kg/day pre-op", "Iron-rich foods if anaemic"], post: ["Hours 0–4: nil by mouth", "Hours 4–8: clear liquids — water, broth, ORS", "Day 1: soft bland diet — porridge, ugali, boiled potatoes", "Day 2–3: semi-solid foods; lean protein (eggs, fish)", "Day 4–7: full diet with iron + vitamin C", "Weeks 2–6: high-fibre diet; 2 L water daily", "Breastfeeding: +500 kcal/day; calcium-rich foods"], keyNutrients: "Iron, Vitamin C, Calcium, Zinc, Omega-3, Protein (≥1.5 g/kg/day)" },
    research: [{ title: "Evidence-based surgical procedures to optimise caesarean outcomes", journal: "eClinicalMedicine / The Lancet", year: 2024, url: "https://www.thelancet.com/journals/eclinm/article/PIIS2589-5370(24)00211-6/fulltext", note: "Overview of 38 systematic reviews, 628 RCTs, 190,349 participants." }]
  },
  {
    id: 2, code: "HERNIA", name: "Inguinal Hernia Repair", specialty: "General Surgery",
    color: "#EBF8FF", accent: "#185fa5",
    overview: "One of the most commonly performed operations worldwide (~800,000/year in the US alone). Inguinal hernias occur when abdominal contents protrude through the inguinal canal. More common in males (lifetime risk ~27% vs 3% females). Three main approaches: open (Lichtenstein mesh), laparoscopic (TEP/TAPP), and robotic.",
    indications: ["Symptomatic inguinal hernia", "Strangulated or incarcerated hernia (emergency)", "Large hernias with risk of incarceration", "Bilateral hernias (laparoscopic preferred)", "Recurrent hernia"],
    procedure: "Open (Lichtenstein): groin incision → hernia sac dissection → mesh placement over defect → suture fixation → closure. Duration ~60–90 min. Laparoscopic TEP: 3 trocars → extraperitoneal dissection → large mesh covering myopectineal orifice.",
    complications: ["Chronic inguinodynia — most common long-term issue", "Recurrence (1–5% with mesh)", "Mesh infection", "Injury to vas deferens / testicular vessels", "Haematoma / seroma", "Nerve injury"],
    diet: { label: "High-Fibre Anti-Straining Protocol", badge: "Custom", pre: ["Start high-fibre diet 1 week pre-op", "Increase fluids to 2 L/day", "Carbohydrate loading night before and 2 hours before"], post: ["Day 0–1: clear liquids; avoid straining", "Day 2–3: soft low-fibre foods (white rice, boiled eggs)", "Day 4–7: gradually reintroduce fibre", "Week 2–6: HIGH-FIBRE diet — fruits, vegetables, whole grains", "Protein: 1.2–1.5 g/kg/day"], keyNutrients: "Fibre (25–35 g/day), Protein, Water, Zinc" },
    research: [{ title: "Open vs laparoscopic vs robotic inguinal hernia repair: systematic review 2025", journal: "PMC / MDPI", year: 2025, url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC11818799/", note: "All three techniques safe; robotic reduces conversion to open." }]
  },
  {
    id: 3, code: "APPY", name: "Appendectomy", specialty: "General Surgery",
    color: "#FFF5F5", accent: "#993c1d",
    overview: "Removal of the vermiform appendix, usually for acute appendicitis. Shortest mean OR time of the 15 common procedures (~51 minutes). Lifetime risk of appendicitis is ~7–8%. Laparoscopic appendectomy (LA) is now the global standard in well-resourced settings.",
    indications: ["Acute appendicitis", "Perforated appendicitis", "Appendiceal abscess (interval appendectomy)", "Appendiceal mucocele"],
    procedure: "Laparoscopic: 3-port technique → pneumoperitoneum → identification of appendix → ligation of mesoappendix → stapler or ligature division of appendix base → extraction via port. Open: McBurney incision. Duration 30–60 min.",
    complications: ["Wound infection", "Intra-abdominal abscess (especially perforated)", "Stump leak", "Ileus", "Port-site hernia"],
    diet: { label: "Low → High Fibre Stepwise Protocol", badge: "Custom", pre: ["Emergency: NBM immediately on diagnosis", "No specific pre-op dietary restriction beyond standard fasting"], post: ["Day 0: clear liquids when alert", "Day 1: low-fibre soft diet — white rice, toast, boiled potato", "Day 2–3: add soft-cooked vegetables", "Day 4–7: gradually increase fibre", "Week 2+: full HIGH-FIBRE diet; 2 L water daily"], keyNutrients: "Protein, Zinc, Vitamin C, Probiotics (post-antibiotic)" },
    research: [{ title: "Laparoscopic vs open appendectomy: meta-analyses in low-resource settings", journal: "Multiple PMC reviews", year: 2023, url: "https://pmc.ncbi.nlm.nih.gov/", note: "Laparoscopic shows fewer wound infections; open remains more accessible in Africa." }]
  },
  {
    id: 4, code: "LAPAROTOMY", name: "Laparotomy (Exploratory)", specialty: "General Surgery",
    color: "#FFFAF0", accent: "#5f5e5a",
    overview: "A large abdominal incision (midline or transverse) to explore the abdominal cavity for unknown pathology. Remains a critical operation in sub-Saharan Africa where advanced imaging and laparoscopy are limited.",
    indications: ["Peritonitis (perforated viscus)", "Trauma (haemoperitoneum)", "Bowel obstruction not resolving", "Abdominal mass requiring surgical staging", "Ectopic pregnancy rupture"],
    procedure: "Midline incision → systematic four-quadrant exploration → identification and management of pathology → haemostasis → irrigation if contaminated → closure. Duration variable: 1–5 hours.",
    complications: ["Wound dehiscence", "Incisional hernia (20–30% long-term)", "Adhesions → small bowel obstruction", "Intra-abdominal sepsis", "Anastomotic leak", "Prolonged ileus"],
    diet: { label: "Modified C-Section Protocol (General Abdominal)", badge: "Modified", pre: ["Standard ERAS carbohydrate loading protocol", "Nutritional optimisation if elective", "Immunonutrition 5 days pre-op if nutritional risk"], post: ["Post-op: NBM until bowel sounds return", "Early oral feeding within 24–48h if no anastomosis", "Start with clear liquids → progress to soft diet over 3–5 days", "High-protein diet: 1.5 g/kg/day"], keyNutrients: "Protein, Glutamine, Zinc, Vitamin A, Electrolytes" },
    research: [{ title: "Surgical Apgar Score Predicts Post-Laparotomy Complications", journal: "Annals of African Surgery", year: 2022, url: "https://www.annalsofafricansurgery.com/10-2", note: "Dullo et al.; Kenyan data — Surgical Apgar Score validated for SSA laparotomy outcomes." }]
  },
  {
    id: 5, code: "HYST", name: "Hysterectomy", specialty: "Gynaecology",
    color: "#FFF5F5", accent: "#993556",
    overview: "Surgical removal of the uterus. The most common non-obstetric major surgery in women worldwide. In Kenya, abdominal hysterectomy predominates. Uterine fibroids are the leading indication in Africa.",
    indications: ["Uterine fibroids (myomas) — most common in Kenya", "Abnormal uterine bleeding", "Endometriosis / adenomyosis", "Uterine prolapse", "Gynaecological cancers"],
    procedure: "TAH: Pfannenstiel or midline incision → ligation of uterine vessels → division of cardinal and uterosacral ligaments → cervical transection → vault closure. Duration 1–2 hours.",
    complications: ["Haemorrhage", "Bladder/ureter injury", "DVT/PE", "Premature menopause (if ovaries removed)", "Pelvic floor dysfunction"],
    diet: { label: "Modified C-Section Protocol + Hormonal Considerations", badge: "Modified", pre: ["ERAS carbohydrate loading", "Correct iron-deficiency anaemia pre-op", "High-protein diet 2 weeks pre-op"], post: ["Day 0: clear liquids 4 hours post-op", "Day 1: low-fat, low-fibre bland diet", "Week 2+: anti-inflammatory diet — omega-3, colourful vegetables", "If bilateral oophorectomy: Calcium 1200 mg/day + Vitamin D3"], keyNutrients: "Iron, Calcium, Vitamin D, Omega-3, Protein" },
    research: [{ title: "ERAS for gynaecological surgery: evidence and implementation", journal: "ESPEN / Clinical Nutrition", year: 2021, url: "https://www.clinicalnutritionjournal.com/article/S0261-5614(21)00178-3/fulltext", note: "ERAS shown effective for hysterectomy, gynaecologic oncology cases." }]
  },
  {
    id: 6, code: "FRACTURE", name: "Open Fracture Repair (ORIF)", specialty: "Orthopaedics",
    color: "#F0FFF4", accent: "#3b6d11",
    overview: "Open reduction and internal fixation of fractured bones using plates, screws, intramedullary nails, or external fixators. Road traffic accidents (RTAs) are the dominant cause in Kenya and Sub-Saharan Africa.",
    indications: ["Displaced fractures requiring anatomic reduction", "Intra-articular fractures", "Open (compound) fractures", "Road traffic accident injuries"],
    procedure: "Fracture exposed/reduced → temporary K-wire fixation → plate and screws OR intramedullary nail → fluoroscopy confirmation → wound closure. Open fractures require urgent irrigation and debridement first. Duration 1–4 hours.",
    complications: ["Infection / osteomyelitis", "Non-union / malunion", "Implant failure", "DVT/PE", "Compartment syndrome", "Fat embolism"],
    diet: { label: "Bone Healing High-Calcium/Protein Protocol", badge: "Modified", pre: ["Emergency: NBM immediately; IV fluids for trauma stabilisation", "Elective: ERAS carbohydrate loading + high-protein pre-op diet"], post: ["Day 0–1: clear liquids when haemodynamically stable", "Week 1+: HIGH-PROTEIN diet (1.5–2.0 g/kg/day)", "Calcium: 1200 mg/day", "Vitamin D3: 800–2000 IU/day", "Vitamin C: 500–1000 mg/day for collagen synthesis"], keyNutrients: "Calcium, Vitamin D3, Vitamin C, Zinc, Protein (2 g/kg/day)" },
    research: [{ title: "Pre- and Post-Surgical Nutrition for Preservation of Muscle Mass Following Orthopedic Surgery", journal: "PMC / Nutrients", year: 2021, url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8156786/", note: "EAAs post-surgery; protein targets; ONS reduce hospitalisation cost by 12.2%." }]
  },
  {
    id: 7, code: "TKR", name: "Knee Replacement (TKR)", specialty: "Orthopaedics",
    color: "#E6F7F5", accent: "#085041",
    overview: "Total knee replacement (TKR) resurfaces the entire knee joint. Primary indication: end-stage osteoarthritis. Oxford Knee Scores improve from ~15 to ~45 post-TKR in SSA studies. A growing procedure in Kenya at both KNH and private hospitals.",
    indications: ["End-stage osteoarthritis", "Rheumatoid arthritis with joint destruction", "Post-traumatic arthritis", "Failed previous knee surgery"],
    procedure: "Medial parapatellar approach → bone cuts (femur, tibia, patella) using cutting guides → trial components → cementation → component placement → closure over drain. Duration 1.5–2.5 hours.",
    complications: ["Infection (deep infection 1.6% in SSA)", "DVT/PE (high risk)", "Aseptic loosening", "Instability", "Stiffness"],
    diet: { label: "High-Protein Musculoskeletal Recovery Protocol", badge: "Custom", pre: ["2 weeks pre-op: HIGH-PROTEIN diet (1.5 g/kg/day)", "Calcium 1200 mg/day + Vitamin D3 800 IU/day", "ERAS carbohydrate loading"], post: ["Day 1: full diet; protein supplementation crucial", "HIGH-PROTEIN: 2.0 g/kg/day", "Anti-inflammatory foods: omega-3, turmeric, ginger", "Calcium + Vitamin D3 continued 6–12 months"], keyNutrients: "Protein (2 g/kg/day), Calcium, Vitamin D, Omega-3, Collagen (Vitamin C)" },
    research: [{ title: "Total joint replacement in sub-Saharan Africa: systematic review", journal: "PMC / Bone & Joint Open", year: 2019, url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC6535807/", note: "606 THRs and 763 TKRs; comparable outcomes; 34% loss to follow-up in Kenya." }]
  },
  {
    id: 8, code: "CHOLE", name: "Cholecystectomy", specialty: "General Surgery",
    color: "#FFFAF0", accent: "#854f0b",
    overview: "Removal of the gallbladder, usually for symptomatic gallstones or cholecystitis. Laparoscopic cholecystectomy (LC) is the gold standard worldwide. A key procedure in East African hospitals as diet patterns shift toward higher fat intake.",
    indications: ["Symptomatic gallstones / biliary colic", "Acute cholecystitis", "Chronic cholecystitis", "Gallbladder polyps >10mm"],
    procedure: "Laparoscopic: 4-port technique → dissection of Calot's triangle → critical view of safety (CVS) → clip and divide cystic duct and artery → specimen extraction. Duration 45–90 min.",
    complications: ["Bile duct injury (most feared: 0.3–0.5%)", "Bile leak", "Haemorrhage", "Post-cholecystectomy syndrome", "Retained common bile duct stone"],
    diet: { label: "Fat-Restricted Progressive Protocol", badge: "Custom", pre: ["2–4 weeks pre-op: LOW-FAT diet (≤30g fat/day)", "Small frequent meals", "Carbohydrate loading the night before and 2h pre-op"], post: ["Day 0–1: clear liquids; no fat", "Week 1: <10g fat/day; introduce small amounts of healthy fats gradually", "Week 2–4: LOW-FAT diet (<30g fat/day); avoid fried foods", "Month 2+: gradually reintroduce normal fats"], keyNutrients: "Low fat, Fibre, Vitamin ADEK, Protein" },
    research: [{ title: "Robot-assisted Procedures in General Surgery: Cholecystectomy, Inguinal and Ventral Hernia Repairs", journal: "NCBI Bookshelf", year: 2020, url: "https://www.ncbi.nlm.nih.gov/books/NBK570695/", note: "Systematic review; robotic shows lower conversion to open; cost-effectiveness debated." }]
  },
  {
    id: 9, code: "MAST", name: "Mastectomy", specialty: "Surgical Oncology",
    color: "#FFF5F5", accent: "#a32d2d",
    overview: "Surgical removal of the breast, primarily for breast cancer. In Kenya and Africa, modified radical mastectomy (MRM) is performed in 64–67% of cases due to advanced disease at presentation. Fear of mastectomy causes significant treatment delays in sub-Saharan Africa.",
    indications: ["Breast cancer (most common)", "BRCA1/2 mutation carrier (prophylactic)", "Locally advanced breast cancer", "Inflammatory breast cancer"],
    procedure: "MRM: elliptical incision around breast → skin flaps raised → breast and axillary lymph node dissection (ALND) → haemostasis → drain placement → closure. Duration 2–4 hours.",
    complications: ["Seroma (most common)", "Lymphoedema of arm", "Wound infection", "Flap necrosis", "Phantom breast pain", "Psychosocial impact — depression, body image"],
    diet: { label: "Modified C-Section Protocol + Oncology Nutrition", badge: "Modified", pre: ["Correct malnutrition pre-op", "Immunonutrition 5–7 days pre-op", "ERAS carbohydrate loading"], post: ["Day 1: light diet — low fat, easy-to-digest", "Week 1–2: anti-cancer, anti-inflammatory foods", "HIGH-PROTEIN: 1.5–2.0 g/kg/day", "Anti-cancer diet: berries, cruciferous vegetables, tomatoes, green tea", "AVOID: alcohol (increases recurrence risk), processed meats"], keyNutrients: "Protein, Omega-3, Antioxidants (Vit C, E), Calcium, Vitamin D" },
    research: [{ title: "Surgical management of breast cancer in Africa: a continent-wide review", journal: "JCO Global Oncology", year: 2017, url: "https://ascopubs.org/doi/10.1200/JGO.2016.003095", note: "MRM >50–90% of cases; breast-conserving surgery rare; stage III–IV most common at presentation." }]
  },
  {
    id: 10, code: "CARDIAC", name: "Cardiac Surgery", specialty: "Cardiac Surgery",
    color: "#FFF5F5", accent: "#791f1f",
    overview: "Open-heart and major cardiac procedures including valve repair/replacement, CABG, and congenital heart disease correction. Sub-Saharan Africa has severely limited cardiac surgery capacity — Kenya's Tenwek Hospital is a landmark local programme. Rheumatic heart disease dominates in Africa.",
    indications: ["Rheumatic heart disease with valve stenosis/regurgitation", "Congenital heart defects (VSD, ASD, TOF)", "Coronary artery disease requiring CABG", "Aortic aneurysm"],
    procedure: "Median sternotomy → cardiopulmonary bypass (CPB) → cardiac arrest (cardioplegia) → specific repair (valve replacement / CABG) → weaning from CPB → chest closure with sternal wires. Duration 3–8 hours. ICU admission mandatory.",
    complications: ["Low cardiac output syndrome", "Arrhythmias (AF most common post-op)", "Stroke", "Bleeding / tamponade", "Acute kidney injury", "Sternal wound infection"],
    diet: { label: "Modified C-Section + Cardiac-Specific Protocol", badge: "Modified", pre: ["Cardiac diet 4–6 weeks pre-op: low sodium (<2g/day), low saturated fat", "Correct malnutrition and anaemia", "Vitamin K restriction if on warfarin"], post: ["LOW SODIUM: <2g/day; reduces fluid overload", "LOW SATURATED FAT: lean meats, fish, plant oils", "HIGH OMEGA-3: fish 3×/week; anti-arrhythmic", "High-protein for sternal wound healing: 1.5–2 g/kg/day", "Fluid restriction if heart failure: typically 1.5 L/day"], keyNutrients: "Low sodium, Omega-3, Potassium, Magnesium, Protein, Vitamin K management" },
    research: [{ title: "Cardiac Surgery in Sub-Saharan Africa: Anthills of the Savannah", journal: "JACC: Advances", year: 2024, url: "https://www.jacc.org/doi/10.1016/j.jacadv.2024.101223", note: "Tenwek Hospital Kenya achieved surgical independence during COVID-19. Rheumatic heart disease dominates." }]
  },
];

const specialties = [...new Set(surgeries.map(s => s.specialty))];

export default function SurgeryReference() {
  const [selected, setSelected] = useState(null);
  const [tab, setTab] = useState("overview");
  const [search, setSearch] = useState("");
  const [specFilter, setSpecFilter] = useState("all");

  const filtered = surgeries.filter(s =>
    (s.name.toLowerCase().includes(search.toLowerCase()) ||
     s.specialty.toLowerCase().includes(search.toLowerCase()) ||
     s.code.toLowerCase().includes(search.toLowerCase())) &&
    (specFilter === "all" || s.specialty === specFilter)
  );

  const tabs = ["overview", "procedure", "diet", "research"];

  if (selected) {
    return (
      <div>
        {/* Back */}
        <button
          onClick={() => setSelected(null)}
          style={{
            display: 'flex', alignItems: 'center', gap: 6, fontSize: 13,
            color: C.textMuted, cursor: 'pointer', background: 'transparent', border: 'none', padding: 0, marginBottom: 20,
          }}
        >
          <ArrowLeft size={14} /> Back to all surgeries
        </button>

        {/* Surgery header */}
        <div style={{
          background: selected.color, border: `1px solid ${selected.accent}40`,
          borderLeft: `4px solid ${selected.accent}`,
          borderRadius: 12, padding: '20px 24px', marginBottom: 20,
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 10 }}>
            <div>
              <div style={{ fontSize: 11, color: selected.accent, fontWeight: 600, marginBottom: 4, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                {selected.specialty} · #{selected.id}
              </div>
              <div style={{ fontSize: 22, fontWeight: 700, color: C.textMain, marginBottom: 2 }}>{selected.name}</div>
              <div style={{ fontSize: 13, color: C.textMuted }}>{selected.code}</div>
            </div>
            <span style={{
              padding: '5px 12px', borderRadius: 20, fontSize: 12, fontWeight: 600,
              background: selected.accent + '18', color: selected.accent,
              border: `1px solid ${selected.accent}40`,
            }}>
              {selected.diet.badge === 'Custom' ? '✓ Custom Protocol' : '⚠ Modified Protocol'}
            </span>
          </div>
        </div>

        {/* Tabs */}
        <div style={{ display: 'flex', gap: 4, marginBottom: 20, flexWrap: 'wrap' }}>
          {tabs.map(t => (
            <button
              key={t}
              onClick={() => setTab(t)}
              style={{
                padding: '8px 18px', borderRadius: 8, fontSize: 13,
                fontWeight: tab === t ? 600 : 400, cursor: 'pointer',
                background: tab === t ? selected.accent : C.surface,
                color: tab === t ? '#fff' : C.textMuted,
                border: `1px solid ${tab === t ? selected.accent : C.border}`,
              }}
            >
              {t.charAt(0).toUpperCase() + t.slice(1)}
            </button>
          ))}
        </div>

        {tab === "overview" && (
          <div>
            <p style={{ fontSize: 14, lineHeight: 1.8, color: C.textMain, marginBottom: 20 }}>{selected.overview}</p>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
              <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 10, padding: '16px 20px' }}>
                <div style={{ fontSize: 11, fontWeight: 600, color: C.textMuted, marginBottom: 12, textTransform: 'uppercase', letterSpacing: '0.5px' }}>Indications</div>
                {selected.indications.map((ind, i) => (
                  <div key={i} style={{ fontSize: 13, color: C.textMain, padding: '5px 0', borderBottom: `1px solid ${C.border}`, display: 'flex', gap: 8 }}>
                    <span style={{ color: selected.accent, fontSize: 12, flexShrink: 0 }}>▸</span> {ind}
                  </div>
                ))}
              </div>
              <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 10, padding: '16px 20px' }}>
                <div style={{ fontSize: 11, fontWeight: 600, color: C.textMuted, marginBottom: 12, textTransform: 'uppercase', letterSpacing: '0.5px' }}>Complications</div>
                {selected.complications.map((c, i) => (
                  <div key={i} style={{ fontSize: 13, color: C.textMain, padding: '5px 0', borderBottom: `1px solid ${C.border}`, display: 'flex', gap: 8 }}>
                    <span style={{ color: C.red, fontSize: 12, flexShrink: 0 }}>!</span> {c}
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {tab === "procedure" && (
          <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 10, padding: '20px' }}>
            <div style={{ fontSize: 11, fontWeight: 600, color: C.textMuted, marginBottom: 12, textTransform: 'uppercase', letterSpacing: '0.5px' }}>Surgical Technique</div>
            <p style={{ fontSize: 14, lineHeight: 1.8, color: C.textMain, whiteSpace: 'pre-wrap' }}>{selected.procedure}</p>
          </div>
        )}

        {tab === "diet" && (
          <div>
            <div style={{ background: selected.color, border: `1px solid ${selected.accent}40`, borderRadius: 10, padding: '12px 18px', marginBottom: 16 }}>
              <span style={{ fontSize: 13, fontWeight: 600, color: selected.accent }}>Key Nutrients: </span>
              <span style={{ fontSize: 13, color: C.textMain }}>{selected.diet.keyNutrients}</span>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
              <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 10, padding: '16px 20px' }}>
                <div style={{ fontSize: 11, fontWeight: 600, color: C.textMuted, marginBottom: 12, textTransform: 'uppercase', letterSpacing: '0.5px' }}>Pre-operative Diet</div>
                {selected.diet.pre.map((item, i) => (
                  <div key={i} style={{ fontSize: 13, color: C.textMain, padding: '5px 0', borderBottom: `1px solid ${C.border}`, lineHeight: 1.5, display: 'flex', gap: 8 }}>
                    <span style={{ color: C.green, flexShrink: 0 }}>→</span> {item}
                  </div>
                ))}
              </div>
              <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 10, padding: '16px 20px' }}>
                <div style={{ fontSize: 11, fontWeight: 600, color: C.textMuted, marginBottom: 12, textTransform: 'uppercase', letterSpacing: '0.5px' }}>Post-operative Diet</div>
                {selected.diet.post.map((item, i) => (
                  <div key={i} style={{ fontSize: 13, color: C.textMain, padding: '5px 0', borderBottom: `1px solid ${C.border}`, lineHeight: 1.5, display: 'flex', gap: 8 }}>
                    <span style={{ color: selected.accent, flexShrink: 0 }}>→</span> {item}
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {tab === "research" && (
          <div>
            <div style={{ fontSize: 13, color: C.textMuted, marginBottom: 16 }}>
              Key research papers, guidelines, and studies — click titles to open source links.
            </div>
            {selected.research.map((r, i) => (
              <div key={i} style={{
                background: C.surface, border: `1px solid ${C.border}`,
                borderLeft: `3px solid ${selected.accent}`,
                borderRadius: 10, padding: '16px 20px', marginBottom: 12,
              }}>
                <a href={r.url} target="_blank" rel="noopener noreferrer"
                  style={{ fontSize: 14, fontWeight: 600, color: selected.accent, textDecoration: 'none', display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6 }}>
                  {r.title} <ExternalLink size={12} />
                </a>
                <div style={{ fontSize: 12, color: C.textMuted, marginBottom: 6 }}>
                  {r.journal} · {r.year}
                </div>
                <div style={{ fontSize: 12, color: C.textMain, lineHeight: 1.6, fontStyle: 'italic' }}>
                  {r.note}
                </div>
              </div>
            ))}
            <div style={{ padding: '14px 18px', borderRadius: 10, background: C.bg, border: `1px solid ${C.border}`, fontSize: 12, color: C.textMuted }}>
              For deeper research: PubMed · Cochrane Library · Annals of African Surgery (annalsofafricansurgery.com) · ESPEN Guidelines
            </div>
          </div>
        )}
      </div>
    );
  }

  return (
    <div>
      {/* Page header */}
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 20, fontWeight: 700, color: C.textMain, margin: 0 }}>Surgery Reference</h1>
        <p style={{ fontSize: 13, color: C.textMuted, margin: '4px 0 0' }}>
          {surgeries.length} procedures — clinical overview, technique, diet protocol, and linked research
        </p>
      </div>

      {/* Search + filter */}
      <div style={{ display: 'flex', gap: 10, marginBottom: 20, alignItems: 'center', flexWrap: 'wrap' }}>
        <div style={{ position: 'relative', flex: 1, minWidth: 200 }}>
          <Search size={14} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: C.textDim }} />
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search by name, code or specialty..."
            style={{
              width: '100%', border: `1px solid ${C.border}`, borderRadius: 8,
              padding: '9px 12px 9px 34px', fontSize: 13, color: C.textMain,
              background: C.surface, outline: 'none', fontFamily: 'inherit', boxSizing: 'border-box',
            }}
          />
        </div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          <button
            onClick={() => setSpecFilter("all")}
            style={{
              padding: '7px 14px', borderRadius: 20, fontSize: 12,
              fontWeight: specFilter === "all" ? 600 : 400,
              border: `1px solid ${specFilter === "all" ? C.primary : C.border}`,
              background: specFilter === "all" ? C.primaryLight : C.surface,
              color: specFilter === "all" ? C.primary : C.textMuted, cursor: 'pointer',
            }}
          >All</button>
          {specialties.map(sp => (
            <button
              key={sp}
              onClick={() => setSpecFilter(sp)}
              style={{
                padding: '7px 14px', borderRadius: 20, fontSize: 12,
                fontWeight: specFilter === sp ? 600 : 400,
                border: `1px solid ${specFilter === sp ? C.primary : C.border}`,
                background: specFilter === sp ? C.primaryLight : C.surface,
                color: specFilter === sp ? C.primary : C.textMuted, cursor: 'pointer',
              }}
            >{sp}</button>
          ))}
        </div>
      </div>

      {/* Surgery cards grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))', gap: 12 }}>
        {filtered.map(sur => (
          <div
            key={sur.id}
            onClick={() => { setSelected(sur); setTab("overview"); }}
            style={{
              background: sur.color, border: `1.5px solid ${sur.accent}30`,
              borderRadius: 12, padding: '18px 20px', cursor: 'pointer',
              transition: 'transform 0.1s, box-shadow 0.1s', userSelect: 'none',
            }}
            onMouseEnter={e => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 4px 20px rgba(0,0,0,0.08)'; }}
            onMouseLeave={e => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = 'none'; }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 8 }}>
              <span style={{ fontSize: 11, fontWeight: 600, color: sur.accent, background: sur.accent + '18', padding: '3px 10px', borderRadius: 20 }}>
                {sur.specialty}
              </span>
              <span style={{ fontSize: 11, color: C.textDim, fontWeight: 500 }}>#{sur.id}</span>
            </div>
            <div style={{ fontSize: 15, fontWeight: 700, color: C.textMain, marginBottom: 3 }}>{sur.name}</div>
            <div style={{ fontSize: 12, color: C.textMuted, marginBottom: 10 }}>{sur.code}</div>
            <div style={{
              fontSize: 11, padding: '4px 10px', borderRadius: 6, display: 'inline-flex', alignItems: 'center', gap: 4,
              background: sur.diet.badge === 'Custom' ? sur.accent + '18' : '#F5F5F5',
              color: sur.diet.badge === 'Custom' ? sur.accent : C.textMuted,
              border: `1px solid ${sur.diet.badge === 'Custom' ? sur.accent + '40' : C.border}`,
            }}>
              {sur.diet.badge === 'Custom' ? '✓' : '⚠'} {sur.diet.label}
            </div>
          </div>
        ))}
      </div>

      {filtered.length === 0 && (
        <div style={{ textAlign: 'center', padding: '48px 0', color: C.textMuted, fontSize: 13 }}>
          No procedures match your search.
        </div>
      )}
    </div>
  );
}
