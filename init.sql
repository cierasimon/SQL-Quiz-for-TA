-- The first six brand/season labels and collection descriptions below are
-- based on the cited Vogue Runway coverage. Additional practice edits and all
-- shoe names, prices, inventory, and sales are simulated, not official brand
-- product or sales information.
-- Sources:
-- https://www.vogue.com/fashion-shows/fall-1993-ready-to-wear/vivienne-westwood
-- https://www.vogue.com/fashion-shows/spring-2024-ready-to-wear/chanel
-- https://www.vogue.com/fashion-shows/spring-2024-ready-to-wear/christian-dior
-- https://www.vogue.com/fashion-shows/spring-2024-ready-to-wear/gucci
-- https://www.vogue.com/fashion-shows/fall-2024-ready-to-wear/ralph-lauren
-- https://www.vogue.com/fashion-shows/spring-2024-ready-to-wear/alexander-mcqueen
-- Three related tables support joins, aggregates, and CTE-based questions.

CREATE TABLE IF NOT EXISTS collections (
  collection_id INT PRIMARY KEY,
  name TEXT NOT NULL,
  season TEXT NOT NULL,
  release_year INT NOT NULL,
  brand TEXT NOT NULL,
  concept TEXT NOT NULL
);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = current_schema()
      AND table_name = 'collections'
      AND column_name = 'designer'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = current_schema()
      AND table_name = 'collections'
      AND column_name = 'brand'
  ) THEN
    ALTER TABLE collections RENAME COLUMN designer TO brand;
  END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS garments (
  garment_id INT PRIMARY KEY,
  collection_id INT NOT NULL REFERENCES collections(collection_id),
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  colorway TEXT NOT NULL,
  material TEXT NOT NULL,
  retail_price NUMERIC(8, 2) NOT NULL CHECK (retail_price >= 0),
  stock_qty INT NOT NULL CHECK (stock_qty >= 0)
);

CREATE TABLE IF NOT EXISTS sales (
  sale_id INT PRIMARY KEY,
  garment_id INT NOT NULL REFERENCES garments(garment_id),
  sold_on DATE NOT NULL,
  customer_city TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('paid', 'shipped', 'cancelled', 'refunded')),
  quantity INT NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(8, 2) NOT NULL CHECK (unit_price >= 0)
);

INSERT INTO collections
  (collection_id, name, season, release_year, brand, concept) VALUES
  (1, 'Anglomania', 'Fall', 1993, 'Vivienne Westwood', 'Vogue Runway dates this collection presentation to March 16, 1993, in Paris.'),
  (2, 'Spring 2024 Ready-to-Wear', 'Spring', 2024, 'Chanel', 'Virginie Viard evoked an easy-living French vacation, with inspiration from the Villa Noailles.'),
  (3, 'Spring 2024 Ready-to-Wear', 'Spring', 2024, 'Dior', 'Maria Grazia Chiuri brought feminist art references and contemporary neo-grunge into the collection.'),
  (4, 'Spring 2024 Ready-to-Wear', 'Spring', 2024, 'Gucci', 'Sabato De Sarno’s debut emphasized wardrobe essentials, cut, and proportion.'),
  (5, 'Fall 2024 Ready-to-Wear', 'Fall', 2024, 'Ralph Lauren', 'The collection revisited Lauren’s timeless style, with tailoring and cinematic western references.'),
  (6, 'Spring 2024 Ready-to-Wear', 'Spring', 2024, 'Alexander McQueen', 'Sarah Burton’s final collection referenced female anatomy, Elizabeth I, the red rose, and artist Magdalena Abakanowicz.'),
  (7, 'Practice Shoe Edit', 'Spring', 2026, 'Maison Margiela', 'Fictional practice collection; not an official brand collection.'),
  (8, 'Practice Shoe Edit', 'Spring', 2026, 'Prada', 'Fictional practice collection; not an official brand collection.'),
  (9, 'Practice Shoe Edit', 'Spring', 2026, 'Christian Louboutin', 'Fictional practice collection; not an official brand collection.'),
  (10, 'Practice Shoe Edit', 'Spring', 2026, 'Manolo Blahnik', 'Fictional practice collection; not an official brand collection.'),
  (11, 'Practice Shoe Edit', 'Spring', 2026, 'Jimmy Choo', 'Fictional practice collection; not an official brand collection.')
ON CONFLICT (collection_id) DO UPDATE SET
  name = EXCLUDED.name,
  season = EXCLUDED.season,
  release_year = EXCLUDED.release_year,
  brand = EXCLUDED.brand,
  concept = EXCLUDED.concept;

INSERT INTO garments
  (garment_id, collection_id, name, category, colorway, material, retail_price, stock_qty) VALUES
  (101, 1, 'Anglomania Orb Platform', 'platform heel', 'oxblood', 'leather', 890.00, 3),
  (102, 1, 'Tartan Court Shoe', 'court heel', 'red tartan', 'textile and leather', 720.00, 7),
  (103, 2, 'Noailles Tweed Slingback', 'slingback heel', 'cream tweed', 'tweed and leather', 1150.00, 4),
  (104, 2, 'Riviera Pearl Sandal', 'heeled sandal', 'black', 'leather', 980.00, 6),
  (105, 3, 'Atelier Lace Pump', 'pump', 'soft ivory', 'lace and leather', 1050.00, 5),
  (106, 3, 'Rue Grunge Ankle Boot', 'ankle boot', 'washed black', 'leather', 1250.00, 8),
  (107, 4, 'Horsebit City Loafer', 'loafer', 'dark brown', 'leather', 990.00, 6),
  (108, 4, 'Brera Patent Mary Jane', 'Mary Jane heel', 'cherry red', 'patent leather', 1080.00, 2),
  (109, 5, 'Madison Glen Plaid Pump', 'pump', 'glen plaid', 'wool textile and leather', 850.00, 5),
  (110, 5, 'Ranch Heritage Boot', 'knee-high boot', 'saddle brown', 'suede leather', 1450.00, 4),
  (111, 6, 'Rose Petal Sculptural Heel', 'sculptural heel', 'deep red', 'leather', 1320.00, 3),
  (112, 6, 'Lace-Up Tailored Ankle Boot', 'ankle boot', 'black', 'leather', 1180.00, 5),
  (113, 7, 'Deconstructed Leather Pump', 'pump', 'chalk white', 'leather', 1090.00, 4),
  (114, 7, 'Sculpted-Toe Ankle Boot', 'ankle boot', 'smoke gray', 'leather', 1390.00, 3),
  (115, 8, 'Minimal Line Slingback', 'slingback heel', 'black', 'leather', 1120.00, 6),
  (116, 8, 'Geometric Heel Mule', 'mule', 'silver', 'metallic leather', 980.00, 5),
  (117, 9, 'Dramatic Arch Stiletto', 'stiletto', 'ruby red', 'satin', 1290.00, 4),
  (118, 9, 'Evening Bow Sandal', 'heeled sandal', 'black', 'leather', 1180.00, 7),
  (119, 10, 'Crystal-Buckle Court Heel', 'court heel', 'midnight blue', 'satin', 1250.00, 3),
  (120, 10, 'Pointed-Toe Evening Pump', 'pump', 'champagne', 'leather', 1160.00, 4),
  (121, 11, 'Feather-Trim Evening Heel', 'evening heel', 'soft pink', 'satin and feathers', 1320.00, 2),
  (122, 11, 'Crystal-Strap Sandal', 'heeled sandal', 'silver', 'metallic leather', 1240.00, 5)
ON CONFLICT (garment_id) DO UPDATE SET
  collection_id = EXCLUDED.collection_id,
  name = EXCLUDED.name,
  category = EXCLUDED.category,
  colorway = EXCLUDED.colorway,
  material = EXCLUDED.material,
  retail_price = EXCLUDED.retail_price,
  stock_qty = EXCLUDED.stock_qty;

INSERT INTO sales
  (sale_id, garment_id, sold_on, customer_city, status, quantity, unit_price) VALUES
  (5001, 101, '2026-01-12', 'Durham', 'shipped', 1, 890.00),
  (5002, 106, '2026-01-12', 'Durham', 'shipped', 2, 1250.00),
  (5003, 103, '2026-01-18', 'New York', 'paid', 1, 1150.00),
  (5004, 111, '2026-01-18', 'New York', 'paid', 1, 1320.00),
  (5005, 104, '2026-02-03', 'Lagos', 'shipped', 1, 980.00),
  (5006, 110, '2026-02-03', 'Lagos', 'shipped', 2, 1450.00),
  (5007, 107, '2026-02-14', 'Osaka', 'cancelled', 1, 990.00),
  (5008, 105, '2026-03-02', 'New Orleans', 'refunded', 1, 1050.00),
  (5009, 102, '2026-03-19', 'Durham', 'shipped', 2, 720.00),
  (5010, 108, '2026-03-19', 'Durham', 'shipped', 1, 1080.00),
  (5011, 109, '2026-04-07', 'New York', 'paid', 1, 850.00),
  (5012, 106, '2026-04-07', 'New York', 'paid', 1, 1250.00),
  (5013, 112, '2026-04-21', 'Osaka', 'shipped', 1, 1180.00),
  (5014, 103, '2026-04-21', 'Osaka', 'shipped', 2, 1150.00),
  (5015, 113, '2026-05-02', 'Durham', 'paid', 1, 1090.00),
  (5016, 115, '2026-05-08', 'New York', 'shipped', 1, 1120.00),
  (5017, 117, '2026-05-15', 'Lagos', 'shipped', 1, 1290.00),
  (5018, 119, '2026-05-21', 'Osaka', 'paid', 1, 1250.00),
  (5019, 121, '2026-06-01', 'New Orleans', 'shipped', 1, 1320.00),
  (5020, 114, '2026-06-07', 'New York', 'paid', 1, 1390.00),
  (5021, 118, '2026-06-14', 'Durham', 'refunded', 1, 1180.00),
  (5022, 122, '2026-06-20', 'Osaka', 'shipped', 1, 1240.00)
ON CONFLICT (sale_id) DO UPDATE SET
  garment_id = EXCLUDED.garment_id,
  sold_on = EXCLUDED.sold_on,
  customer_city = EXCLUDED.customer_city,
  status = EXCLUDED.status,
  quantity = EXCLUDED.quantity,
  unit_price = EXCLUDED.unit_price;