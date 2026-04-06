-- ============================================================
-- SalamaRecover: Seed Nairobi Hospitals
-- Real Kenyan hospitals with actual phone numbers and coordinates
-- ============================================================

INSERT INTO hospitals (name, type, address, phone, lat, lng) VALUES

-- Major Public Hospitals
('Kenyatta National Hospital', 'public',
 'Hospital Rd, Upper Hill, Nairobi', '+254-20-2726300',
 -1.3011, 36.8073),

('Mama Lucy Kibaki Hospital', 'public',
 'Kangundo Rd, Embakasi, Nairobi', '+254-20-2019100',
 -1.2964, 36.8978),

('Mbagathi County Hospital', 'public',
 'Mbagathi Way, Nairobi', '+254-20-2725200',
 -1.3175, 36.7950),

('Pumwani Maternity Hospital', 'public',
 'Pumwani Rd, Eastleigh, Nairobi', '+254-20-2726550',
 -1.2750, 36.8500),

-- Major Private Hospitals
('Nairobi Hospital', 'private',
 'Argwings Kodhek Rd, Nairobi', '+254-20-2845000',
 -1.2964, 36.8100),

('Aga Khan University Hospital', 'private',
 '3rd Parklands Ave, Nairobi', '+254-20-3662000',
 -1.2614, 36.8175),

('MP Shah Hospital', 'private',
 'Shivachi Rd, Parklands, Nairobi', '+254-20-4291000',
 -1.2611, 36.8136),

('Karen Hospital', 'private',
 'Karen Rd, Karen, Nairobi', '+254-20-8842000',
 -1.3256, 36.7150),

('Nairobi West Hospital', 'private',
 'Gandhinagar Rd, Nairobi West', '+254-20-2720780',
 -1.3108, 36.8200),

('Coptic Hospital', 'private',
 'Ngong Rd, Nairobi', '+254-20-2710568',
 -1.3000, 36.7900),

('Mater Misericordiae Hospital', 'mission',
 'Dunga Rd, South B, Nairobi', '+254-20-6903000',
 -1.3100, 36.8300),

('St. Mary''s Mission Hospital', 'mission',
 'Langata Rd, Nairobi', '+254-20-2603644',
 -1.3400, 36.7600),

-- Emergency / Trauma Centers
('Kenyatta National Hospital A&E', 'emergency',
 'Hospital Rd, Upper Hill, Nairobi', '+254-20-2726300',
 -1.3011, 36.8073),

('Avenue Healthcare', 'private',
 'Limuru Rd, Parklands, Nairobi', '+254-20-2330078',
 -1.2550, 36.8100),

('Metropolitan Hospital', 'private',
 'Busia Rd, South B, Nairobi', '+254-20-6007999',
 -1.3100, 36.8350),

-- Satellite Towns (patients may be recovering outside Nairobi)
('Thika Level 5 Hospital', 'public',
 'Kenyatta Ave, Thika', '+254-67-2022511',
 -1.0396, 37.0693),

('Kiambu Level 5 Hospital', 'public',
 'Kiambu Rd, Kiambu', '+254-66-2022077',
 -1.1714, 36.8356),

('Machakos Level 5 Hospital', 'public',
 'Machakos Town', '+254-44-2021077',
 -1.5177, 37.2634);
