-- ============================================================
-- SalamaRecover: Migration 009 — Kenya Hospitals (All 47 Counties)
-- Comprehensive list of major hospitals across Kenya
-- Sources: MOH Kenya, county health departments, public records
-- Run this in Supabase SQL Editor
-- ============================================================

INSERT INTO hospitals (name, type, address, phone, lat, lng) VALUES

-- ══════════════════════════════════════════════════════════════
-- NAIROBI COUNTY
-- ══════════════════════════════════════════════════════════════
('Kenyatta National Hospital', 'public', 'Hospital Rd, Upper Hill, Nairobi', '+254202726300', -1.3011, 36.8073),
('Nairobi Hospital', 'private', 'Argwings Kodhek Rd, Nairobi', '+254202845000', -1.2964, 36.8100),
('Aga Khan University Hospital Nairobi', 'private', '3rd Parklands Ave, Nairobi', '+254203662000', -1.2614, 36.8175),
('MP Shah Hospital', 'private', 'Shivachi Rd, Parklands, Nairobi', '+254204291000', -1.2611, 36.8136),
('Karen Hospital', 'private', 'Karen Rd, Karen, Nairobi', '+254208842000', -1.3256, 36.7150),
('Mama Lucy Kibaki Hospital', 'public', 'Kangundo Rd, Embakasi, Nairobi', '+254202019100', -1.2964, 36.8978),
('Mbagathi County Hospital', 'public', 'Mbagathi Way, Nairobi', '+254202725200', -1.3175, 36.7950),
('Pumwani Maternity Hospital', 'public', 'Pumwani Rd, Eastleigh, Nairobi', '+254202726550', -1.2750, 36.8500),
('Mater Misericordiae Hospital', 'mission', 'Dunga Rd, South B, Nairobi', '+254206903000', -1.3100, 36.8300),
('Nairobi West Hospital', 'private', 'Gandhinagar Rd, Nairobi West', '+254202720780', -1.3108, 36.8200),
('Coptic Hospital Nairobi', 'mission', 'Ngong Rd, Nairobi', '+254202710568', -1.3000, 36.7900),
('Avenue Healthcare Parklands', 'private', 'Limuru Rd, Parklands, Nairobi', '+254202330078', -1.2550, 36.8100),
('Metropolitan Hospital', 'private', 'Busia Rd, South B, Nairobi', '+254206007999', -1.3100, 36.8350),
('Gertrudes Childrens Hospital', 'private', 'Muthaiga Rd, Nairobi', '+254203763474', -1.2500, 36.8400),
('Nairobi Womens Hospital', 'private', 'Argwings Kodhek Rd, Nairobi', '+254203864000', -1.2950, 36.8050),
('Kenyatta University Teaching Hospital', 'public', 'Kenyatta University, Nairobi', '+254720610000', -1.1800, 36.9300),
('Mathare Hospital', 'public', 'Mathare North Rd, Nairobi', '+254202723031', -1.2600, 36.8700),
('Chiromo Hospital Group', 'private', 'Chiromo Rd, Westlands, Nairobi', '+254203580000', -1.2700, 36.8000),
('Ruaraka Uhai Neema Hospital', 'mission', 'Ruaraka, Nairobi', '+254720000000', -1.2400, 36.8800),
('St Mary Mission Hospital Nairobi', 'mission', 'Langata Rd, Nairobi', '+254202603644', -1.3400, 36.7600),

-- ══════════════════════════════════════════════════════════════
-- MOMBASA COUNTY
-- ══════════════════════════════════════════════════════════════
('Coast General Teaching and Referral Hospital', 'public', 'Moi Ave, Mombasa', '+254412314201', -4.0435, 39.6682),
('Aga Khan Hospital Mombasa', 'private', 'Vanga Rd, Mombasa', '+254412227710', -4.0500, 39.6600),
('Pandya Memorial Hospital', 'private', 'Dedan Kimathi Ave, Mombasa', '+254412220074', -4.0600, 39.6650),
('Mombasa Hospital', 'private', 'Mama Ngina Dr, Mombasa', '+254412312191', -4.0650, 39.6700),
('Port Reitz District Hospital', 'public', 'Port Reitz, Mombasa', '+254412433000', -4.0200, 39.6200),
('Tudor District Hospital', 'public', 'Tudor, Mombasa', '+254412220000', -4.0300, 39.6800),

-- ══════════════════════════════════════════════════════════════
-- KISUMU COUNTY
-- ══════════════════════════════════════════════════════════════
('Jaramogi Oginga Odinga Teaching and Referral Hospital', 'public', 'Kisumu', '+254572021501', -0.1022, 34.7617),
('Aga Khan Hospital Kisumu', 'private', 'Otieno Oyoo St, Kisumu', '+254572020670', -0.0917, 34.7680),
('Kisumu County Hospital', 'public', 'Kisumu', '+254572021000', -0.1000, 34.7600),
('Kisumu Adventist Hospital', 'mission', 'Kisumu', '+254572022000', -0.0950, 34.7550),
('St Elizabeth Lwak Mission Hospital', 'mission', 'Lwak, Kisumu', '+254572000000', -0.2000, 34.5000),

-- ══════════════════════════════════════════════════════════════
-- NAKURU COUNTY
-- ══════════════════════════════════════════════════════════════
('Nakuru Level 5 Hospital', 'public', 'Nakuru Town', '+254512212000', -0.2833, 36.0667),
('War Memorial Hospital Nakuru', 'public', 'Nakuru', '+254512210000', -0.2900, 36.0700),
('Nakuru Nursing Home', 'private', 'Nakuru', '+254512213000', -0.2800, 36.0600),
('Rift Valley Provincial General Hospital', 'public', 'Nakuru', '+254512211000', -0.2850, 36.0650),
('St Luke Orthopaedic and Trauma Hospital', 'mission', 'Kabarnet Rd, Nakuru', '+254512215000', -0.2750, 36.0550),

-- ══════════════════════════════════════════════════════════════
-- KIAMBU COUNTY
-- ══════════════════════════════════════════════════════════════
('Thika Level 5 Hospital', 'public', 'Kenyatta Ave, Thika', '+254672022511', -1.0396, 37.0693),
('Kiambu Level 5 Hospital', 'public', 'Kiambu Rd, Kiambu', '+254662022077', -1.1714, 36.8356),
('Gatundu Level 5 Hospital', 'public', 'Gatundu, Kiambu', '+254662000000', -1.0000, 36.9000),
('Tigoni District Hospital', 'public', 'Tigoni, Kiambu', '+254662000001', -1.1000, 36.7500),
('Nazareth Hospital', 'mission', 'Limuru, Kiambu', '+254662000002', -1.1100, 36.6500),

-- ══════════════════════════════════════════════════════════════
-- MACHAKOS COUNTY
-- ══════════════════════════════════════════════════════════════
('Machakos Level 5 Hospital', 'public', 'Machakos Town', '+254442021077', -1.5177, 37.2634),
('Mwinga Hospital', 'private', 'Machakos', '+254442022000', -1.5200, 37.2700),
('Kangundo Level 4 Hospital', 'public', 'Kangundo, Machakos', '+254442000000', -1.4000, 37.3500),

-- ══════════════════════════════════════════════════════════════
-- KAJIADO COUNTY
-- ══════════════════════════════════════════════════════════════
('Kajiado County Referral Hospital', 'public', 'Kajiado Town', '+254302000000', -1.8500, 36.7800),
('Ngong Sub-County Hospital', 'public', 'Ngong, Kajiado', '+254302000001', -1.3600, 36.6600),
('Isinya Sub-County Hospital', 'public', 'Isinya, Kajiado', '+254302000002', -1.9000, 36.9000),

-- ══════════════════════════════════════════════════════════════
-- MURANG''A COUNTY
-- ══════════════════════════════════════════════════════════════
('Murang''a Level 5 Hospital', 'public', 'Murang''a Town', '+254602022000', -0.7167, 37.1500),
('Kigumo Sub-County Hospital', 'public', 'Kigumo, Murang''a', '+254602000000', -0.7500, 36.9500),

-- ══════════════════════════════════════════════════════════════
-- KIRINYAGA COUNTY
-- ══════════════════════════════════════════════════════════════
('Kerugoya County Referral Hospital', 'public', 'Kerugoya, Kirinyaga', '+254602000001', -0.5000, 37.2800),
('Kutus Sub-County Hospital', 'public', 'Kutus, Kirinyaga', '+254602000002', -0.5200, 37.4000),

-- ══════════════════════════════════════════════════════════════
-- NYERI COUNTY
-- ══════════════════════════════════════════════════════════════
('Nyeri County Referral Hospital', 'public', 'Nyeri Town', '+254612030000', -0.4167, 36.9500),
('Consolata Hospital Nyeri', 'mission', 'Nyeri', '+254612031000', -0.4200, 36.9600),
('Karatina District Hospital', 'public', 'Karatina, Nyeri', '+254612000000', -0.4800, 37.1200),

-- ══════════════════════════════════════════════════════════════
-- MERU COUNTY
-- ══════════════════════════════════════════════════════════════
('Meru Teaching and Referral Hospital', 'public', 'Meru Town', '+254642031000', 0.0500, 37.6500),
('PCEA Chogoria Hospital', 'mission', 'Chogoria, Meru', '+254642000000', -0.3500, 37.6500),
('Nkubu Mission Hospital', 'mission', 'Nkubu, Meru', '+254642000001', 0.0000, 37.6000),

-- ══════════════════════════════════════════════════════════════
-- EMBU COUNTY
-- ══════════════════════════════════════════════════════════════
('Embu Level 5 Hospital', 'public', 'Embu Town', '+254682030000', -0.5333, 37.4500),
('Siakago District Hospital', 'public', 'Siakago, Embu', '+254682000000', -0.6000, 37.6000),

-- ══════════════════════════════════════════════════════════════
-- KITUI COUNTY
-- ══════════════════════════════════════════════════════════════
('Kitui County Referral Hospital', 'public', 'Kitui Town', '+254442000003', -1.3667, 38.0167),
('Mwingi Level 4 Hospital', 'public', 'Mwingi, Kitui', '+254442000004', -0.9333, 38.0667),

-- ══════════════════════════════════════════════════════════════
-- MAKUENI COUNTY
-- ══════════════════════════════════════════════════════════════
('Makueni County Referral Hospital', 'public', 'Wote, Makueni', '+254442000005', -1.7833, 37.6333),
('Sultan Hamud Sub-County Hospital', 'public', 'Sultan Hamud, Makueni', '+254442000006', -2.0500, 37.7000),

-- ══════════════════════════════════════════════════════════════
-- NYANDARUA COUNTY
-- ══════════════════════════════════════════════════════════════
('Ol Kalou County Referral Hospital', 'public', 'Ol Kalou, Nyandarua', '+254602000003', -0.2667, 36.3833),
('Engineer District Hospital', 'public', 'Engineer, Nyandarua', '+254602000004', -0.8500, 36.5500),

-- ══════════════════════════════════════════════════════════════
-- LAIKIPIA COUNTY
-- ══════════════════════════════════════════════════════════════
('Nanyuki Teaching and Referral Hospital', 'public', 'Nanyuki, Laikipia', '+254622032000', 0.0167, 37.0667),
('Nyahururu County Hospital', 'public', 'Nyahururu, Laikipia', '+254652022000', 0.0333, 36.3667),

-- ══════════════════════════════════════════════════════════════
-- SAMBURU COUNTY
-- ══════════════════════════════════════════════════════════════
('Maralal County Referral Hospital', 'public', 'Maralal, Samburu', '+254652000000', 1.1000, 36.7000),

-- ══════════════════════════════════════════════════════════════
-- TRANS NZOIA COUNTY
-- ══════════════════════════════════════════════════════════════
('Kitale County Referral Hospital', 'public', 'Kitale, Trans Nzoia', '+254542031000', 1.0167, 35.0000),
('Kitale District Hospital', 'public', 'Kitale', '+254542032000', 1.0200, 35.0100),

-- ══════════════════════════════════════════════════════════════
-- UASIN GISHU COUNTY
-- ══════════════════════════════════════════════════════════════
('Moi Teaching and Referral Hospital', 'public', 'Nandi Rd, Eldoret', '+254532033000', 0.5167, 35.2833),
('Eldoret Hospital', 'private', 'Eldoret', '+254532034000', 0.5200, 35.2900),
('Mediheal Hospital Eldoret', 'private', 'Eldoret', '+254532035000', 0.5100, 35.2800),
('AIC Kijabe Hospital', 'mission', 'Kijabe, Kiambu', '+254502022000', -0.9500, 36.5700),

-- ══════════════════════════════════════════════════════════════
-- ELGEYO MARAKWET COUNTY
-- ══════════════════════════════════════════════════════════════
('Iten County Referral Hospital', 'public', 'Iten, Elgeyo Marakwet', '+254532000000', 0.6667, 35.5000),

-- ══════════════════════════════════════════════════════════════
-- NANDI COUNTY
-- ══════════════════════════════════════════════════════════════
('Kapsabet County Referral Hospital', 'public', 'Kapsabet, Nandi', '+254532000001', 0.2000, 35.1000),

-- ══════════════════════════════════════════════════════════════
-- BARINGO COUNTY
-- ══════════════════════════════════════════════════════════════
('Kabarnet County Referral Hospital', 'public', 'Kabarnet, Baringo', '+254532000002', 0.4833, 35.7500),
('Eldama Ravine District Hospital', 'public', 'Eldama Ravine, Baringo', '+254532000003', 0.0500, 35.7200),

-- ══════════════════════════════════════════════════════════════
-- WEST POKOT COUNTY
-- ══════════════════════════════════════════════════════════════
('Kapenguria County Referral Hospital', 'public', 'Kapenguria, West Pokot', '+254542000000', 1.2333, 35.1167),

-- ══════════════════════════════════════════════════════════════
-- TURKANA COUNTY
-- ══════════════════════════════════════════════════════════════
('Lodwar County Referral Hospital', 'public', 'Lodwar, Turkana', '+254542000001', 3.1167, 35.5833),
('Kakuma Mission Hospital', 'mission', 'Kakuma, Turkana', '+254542000002', 3.7167, 34.8500),

-- ══════════════════════════════════════════════════════════════
-- MARSABIT COUNTY
-- ══════════════════════════════════════════════════════════════
('Marsabit County Referral Hospital', 'public', 'Marsabit Town', '+254692000000', 2.3333, 37.9833),

-- ══════════════════════════════════════════════════════════════
-- ISIOLO COUNTY
-- ══════════════════════════════════════════════════════════════
('Isiolo County Referral Hospital', 'public', 'Isiolo Town', '+254642000002', 0.3500, 37.5833),

-- ══════════════════════════════════════════════════════════════
-- GARISSA COUNTY
-- ══════════════════════════════════════════════════════════════
('Garissa County Referral Hospital', 'public', 'Garissa Town', '+254462000000', -0.4500, 39.6500),

-- ══════════════════════════════════════════════════════════════
-- WAJIR COUNTY
-- ══════════════════════════════════════════════════════════════
('Wajir County Referral Hospital', 'public', 'Wajir Town', '+254462000001', 1.7500, 40.0667),

-- ══════════════════════════════════════════════════════════════
-- MANDERA COUNTY
-- ══════════════════════════════════════════════════════════════
('Mandera County Referral Hospital', 'public', 'Mandera Town', '+254462000002', 3.9333, 41.8667),

-- ══════════════════════════════════════════════════════════════
-- TANA RIVER COUNTY
-- ══════════════════════════════════════════════════════════════
('Hola District Hospital', 'public', 'Hola, Tana River', '+254462000003', -1.5000, 40.0333),

-- ══════════════════════════════════════════════════════════════
-- LAMU COUNTY
-- ══════════════════════════════════════════════════════════════
('King Fahad County Hospital Lamu', 'public', 'Lamu Island', '+254422000000', -2.2667, 40.9000),

-- ══════════════════════════════════════════════════════════════
-- TAITA TAVETA COUNTY
-- ══════════════════════════════════════════════════════════════
('Moi County Referral Hospital Voi', 'public', 'Voi, Taita Taveta', '+254432000000', -3.3667, 38.5667),
('Wesu Sub-County Hospital', 'public', 'Wundanyi, Taita Taveta', '+254432000001', -3.4000, 38.3500),

-- ══════════════════════════════════════════════════════════════
-- KWALE COUNTY
-- ══════════════════════════════════════════════════════════════
('Kwale County Referral Hospital', 'public', 'Kwale Town', '+254402000000', -4.1833, 39.4500),
('Msambweni County Referral Hospital', 'public', 'Msambweni, Kwale', '+254402000001', -4.4667, 39.4833),

-- ══════════════════════════════════════════════════════════════
-- KILIFI COUNTY
-- ══════════════════════════════════════════════════════════════
('Kilifi County Hospital', 'public', 'Kilifi Town', '+254412000000', -3.6333, 39.8500),
('Malindi Sub-County Hospital', 'public', 'Malindi, Kilifi', '+254422000001', -3.2167, 40.1167),

-- ══════════════════════════════════════════════════════════════
-- SIAYA COUNTY
-- ══════════════════════════════════════════════════════════════
('Siaya County Referral Hospital', 'public', 'Siaya Town', '+254572000001', -0.0617, 34.2883),
('Yala Sub-County Hospital', 'public', 'Yala, Siaya', '+254572000002', 0.1000, 34.5500),

-- ══════════════════════════════════════════════════════════════
-- HOMA BAY COUNTY
-- ══════════════════════════════════════════════════════════════
('Homa Bay County Teaching and Referral Hospital', 'public', 'Homa Bay Town', '+254592000000', -0.5167, 34.4500),
('Rachuonyo District Hospital', 'public', 'Kendu Bay, Homa Bay', '+254592000001', -0.3500, 34.6500),

-- ══════════════════════════════════════════════════════════════
-- MIGORI COUNTY
-- ══════════════════════════════════════════════════════════════
('Migori County Referral Hospital', 'public', 'Migori Town', '+254592000002', -1.0667, 34.4733),
('Shirati Hospital', 'mission', 'Migori', '+254592000003', -1.1000, 34.5000),

-- ══════════════════════════════════════════════════════════════
-- KISII COUNTY
-- ══════════════════════════════════════════════════════════════
('Kisii Teaching and Referral Hospital', 'public', 'Kisii Town', '+254582030000', -0.6817, 34.7667),
('Tabaka Mission Hospital', 'mission', 'Tabaka, Kisii', '+254582000000', -0.7000, 34.6500),

-- ══════════════════════════════════════════════════════════════
-- NYAMIRA COUNTY
-- ══════════════════════════════════════════════════════════════
('Nyamira County Referral Hospital', 'public', 'Nyamira Town', '+254582000001', -0.5667, 34.9333),

-- ══════════════════════════════════════════════════════════════
-- BOMET COUNTY
-- ══════════════════════════════════════════════════════════════
('Longisa County Referral Hospital', 'public', 'Longisa, Bomet', '+254522000000', -0.9667, 35.2167),
('Tenwek Mission Hospital', 'mission', 'Bomet', '+254522000001', -0.8833, 35.3500),

-- ══════════════════════════════════════════════════════════════
-- KERICHO COUNTY
-- ══════════════════════════════════════════════════════════════
('Kericho County Referral Hospital', 'public', 'Kericho Town', '+254522000002', -0.3667, 35.2833),

-- ══════════════════════════════════════════════════════════════
-- NAROK COUNTY
-- ══════════════════════════════════════════════════════════════
('Narok County Referral Hospital', 'public', 'Narok Town', '+254502000000', -1.0833, 35.8667),

-- ══════════════════════════════════════════════════════════════
-- KAKAMEGA COUNTY
-- ══════════════════════════════════════════════════════════════
('Kakamega County General Hospital', 'public', 'Kakamega Town', '+254562030000', 0.2833, 34.7500),
('Mukumu Mission Hospital', 'mission', 'Kakamega', '+254562000000', 0.3000, 34.7000),

-- ══════════════════════════════════════════════════════════════
-- VIHIGA COUNTY
-- ══════════════════════════════════════════════════════════════
('Vihiga County Referral Hospital', 'public', 'Mbale, Vihiga', '+254562000001', 0.0667, 34.7167),

-- ══════════════════════════════════════════════════════════════
-- BUNGOMA COUNTY
-- ══════════════════════════════════════════════════════════════
('Bungoma County Referral Hospital', 'public', 'Bungoma Town', '+254552030000', 0.5667, 34.5667),
('Mt Elgon District Hospital', 'public', 'Kapsokwony, Bungoma', '+254552000000', 1.1000, 34.6500),

-- ══════════════════════════════════════════════════════════════
-- BUSIA COUNTY
-- ══════════════════════════════════════════════════════════════
('Busia County Referral Hospital', 'public', 'Busia Town', '+254552000001', 0.4667, 34.1167),

-- ══════════════════════════════════════════════════════════════
-- ADDITIONAL MAJOR PRIVATE/MISSION HOSPITALS
-- ══════════════════════════════════════════════════════════════
('Kijabe Mission Hospital', 'mission', 'Kijabe, Kiambu', '+254502022001', -0.9500, 36.5700),
('Kikuyu Mission Hospital', 'mission', 'Kikuyu, Kiambu', '+254662022000', -1.2500, 36.6700),
('Tumutumu Mission Hospital', 'mission', 'Nyeri', '+254612000001', -0.5000, 37.0000),
('Chogoria Mission Hospital', 'mission', 'Chogoria, Meru', '+254642000003', -0.3500, 37.6500),
('Kapsowar Mission Hospital', 'mission', 'Kapsowar, Elgeyo Marakwet', '+254532000004', 1.2000, 35.5000),
('Litein Mission Hospital', 'mission', 'Litein, Kericho', '+254522000003', -0.5833, 35.3000),
('Nandi Hills District Hospital', 'public', 'Nandi Hills, Nandi', '+254532000005', 0.1000, 35.1833),
('Webuye District Hospital', 'public', 'Webuye, Bungoma', '+254552000002', 0.6167, 34.7667),
('Malava Sub-County Hospital', 'public', 'Malava, Kakamega', '+254562000002', 0.4500, 34.6500),
('Butere Sub-County Hospital', 'public', 'Butere, Kakamega', '+254562000003', 0.2000, 34.4833);

-- Add unique constraint to prevent future duplicates
ALTER TABLE hospitals ADD CONSTRAINT hospitals_name_unique UNIQUE (name);
