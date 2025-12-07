-- Add 'quote' column to users table
-- Run this in Supabase SQL Editor

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS quote TEXT DEFAULT 'Stay vigilant, stay secure';

-- Update existing users with default quotes (optional - they already have default from column definition)
-- But you can set different default quotes for variety:

UPDATE users 
SET quote = CASE 
    WHEN quote IS NULL OR quote = '' THEN 'Stay vigilant, stay secure'
    ELSE quote
END;

-- You can also set random quotes for existing users for variety (optional):
/*
UPDATE users 
SET quote = (
    SELECT quote FROM (
        VALUES 
            ('Stay vigilant, stay secure'),
            ('Security is not a product, but a process'),
            ('Think before you click'),
            ('Your digital guardian'),
            ('Cyber defender in training'),
            ('Security first, always')
    ) AS quotes(quote)
    ORDER BY RANDOM()
    LIMIT 1
)
WHERE quote IS NULL OR quote = '';
*/
