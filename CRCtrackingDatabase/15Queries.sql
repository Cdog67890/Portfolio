-- 1. All metadata for a single lesion
SELECT * FROM lesion l
LEFT JOIN lesion_info i ON l.lesion_id = i.unique_object_id
LEFT JOIN diagnosis d ON l.lesion_id = d.lesion_id
LEFT JOIN lesion_outcome o ON l.lesion_id = o.lesion_id
WHERE l.lesion_id = 'adenoma_8';



-- 2. Expert accuracy for a given lesion
SELECT lesion_id, avg_expert_claim, expert_accuracy
FROM classification
WHERE lesion_id = 'serrated_8';



-- 3. Measurements associated with a given lesion
SELECT metric_name, metric_value
FROM measurement
WHERE lesion_id = 'adenoma_2';



-- 4. An overview of lesion classification (this spans an entire table but shows an example of one instance)
CREATE OR REPLACE VIEW lesion_summary AS 
SELECT 
	l.lesion_id, l.ground_truth, 
	i."size [mm]", i.site, 
	o.tumor_confirmation, 
	c.expert_accuracy, 
	m2.metric_value AS numeric_value
FROM lesion l 
LEFT JOIN lesion_info i ON l.lesion_id = i.unique_object_id
LEFT JOIN lesion_outcome o ON l.lesion_id = o.lesion_id
LEFT JOIN classification c ON l.lesion_id = c.lesion_id
LEFT JOIN measurement m2 ON l.lesion_id = m2.lesion_id
							AND m2.metric_name = 'Numeric_Value'; 


SELECT * FROM lesion_summary
WHERE lesion_id = 'serrated_8';



-- 5. Average lesion size by histology
SELECT i.histology_extended, ROUND(AVG(i."size [mm]"), 2) AS avg_size_mm
FROM lesion_info i
GROUP BY i.histology_extended 
ORDER BY avg_size_mm DESC;



-- 6. Expert vs. Beginner accuracy queries (keep in mind that there are 4 experts and 3 beginners)

SELECT 
	ROUND(AVG(expert_accuracy), 2) AS expert_accuracy,
	ROUND(AVG(beginner_accuracy), 2) AS beginner_accuracy
FROM classification;

SELECT 
	lesion_type, 
	ROUND(AVG(expert_accuracy), 2) AS expert_accuracy,
	ROUND(AVG(beginner_accuracy), 2) AS beginner_accuracy
FROM classification
GROUP BY lesion_type;

SELECT * FROM classification 
WHERE beginner_accuracy > expert_accuracy;



-- 7. The Metric Value provided does not seem significant enough to predict lesion type
SELECT ROUND(STDDEV(metric_value), 2) AS stddev_numeric_value FROM measurement;

SELECT m.metric_value, c.expert_accuracy FROM measurement m
JOIN classification c ON m.lesion_id = c.lesion_id
WHERE metric_value IS NOT NULL;

SELECT CORR(m.metric_value, c.expert_accuracy) AS corr_metric_expert_accuracy FROM measurement m
JOIN classification c ON m.lesion_id = c.lesion_id;

SELECT CORR(m.metric_value, c.beginner_accuracy) AS corr_metric_beginner_accuracy FROM measurement m
JOIN classification c ON m.lesion_id = c.lesion_id;



-- 8. What is the average actual status of a polyp:
SELECT 
	ground_truth AS lesion_type, 
	COUNT(lesion_id) AS total_count,
	ROUND(
	(COUNT(lesion_id) * 100) / (SELECT COUNT(*) FROM lesion), 2
	)AS percetage_total
FROM lesion 
GROUP BY ground_truth
ORDER BY total_count DESC;



-- 12. Finding cases of misdiagnosis’
SELECT l.ground_truth, c.avg_expert_claim, COUNT (*) AS cases FROM classification c
JOIN lesion l ON c.lesion_id = l.lesion_id
WHERE l.ground_truth <> c.avg_expert_claim
GROUP BY l.ground_truth, c.avg_expert_claim
ORDER BY cases;



-- 13. Determining risk per lesion
SELECT lesion_id, avg_expert_claim, expert_accuracy, 
	CASE
		WHEN expert_accuracy > 70 THEN 'HIGH RISK'
		WHEN expert_accuracy > 50 AND expert_accuracy < 69 THEN 'MODERATE RISK'
		ELSE 'LOW RISK'
	END AS risk_level
FROM classification;

SELECT lesion_id, avg_beginner_claim, beginner_accuracy, 
	CASE
		WHEN beginner_accuracy > 70 THEN 'HIGH RISK'
		WHEN beginner_accuracy > 50 AND beginner_accuracy < 69 THEN 'MODERATE RISK'
		ELSE 'LOW RISK'
	END AS risk_level
FROM classification;



-- Total counts of each lesion (I already cleaned the histology class earlier to help categorize complex names given to different lesions by using LIKE/ILIKE)

SELECT histology_class AS lesion_type, COUNT (*) AS total_lesions FROM lesion_outcome
GROUP BY histology_class
ORDER BY total_lesions DESC;



-- 15. Finding where histological sites are commonly found in colorectal tract 
SELECT 
	i.site AS lesion_site, 
	i.histology_extended AS histology, 
	COUNT(i.unique_object_id) AS total_lesions
FROM lesion_info i
GROUP BY i.site, i.histology_extended 
ORDER BY total_lesions DESC, lesion_site ASC;



-- BONUS. Might be helpful later for visualization
SELECT "Crohn’s disease", crc_percentage FROM crc_clean
ORDER BY crc_percentage DESC;