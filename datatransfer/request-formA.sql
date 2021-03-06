# gender: M  (male),  F (female)
# status: 1 (active), 0 (inactive), -1 (dead)
# SBMC: S (still birth), M (miscarriage)
# Delivered in HF: Y (yes), N (no), U (unknown)

DROP TABLE IF EXISTS `cc_export_tmp`;

CREATE TEMPORARY TABLE `cc_export_tmp`
SELECT 'Seq', 'patient_name', 'delta_days', 'encounter_date', 'encounter_date_mod', 'encounter_year_mod', 'encounter_month_mod', 
'encounter_day_mod', 'patient_dob', 'patient_dob_mod', 'age_at_encounter', 'original_encounter_date', 'patient_registered_on_mod', 
'patient_id', 'location', 'patient_gender', 'hohh_id', 'hohh', 'mother_id', 'mother', 'chw', 'bir_delivered_in_hf',
'bir_weight', 'status', 'death_date', 'death_date_mod', 'sbmc_date', 'sbmc_date_mod', 'sbmc_type', 'source'
UNION 
SELECT 
        e.id as Seq, 

       # debug only
     (SELECT CONCAT(p.first_name, " ", p.last_name) FROM cc_patient as p WHERE p.id=e.patient_id) as patient_name, 

    (SELECT rp.days FROM cc_patient as p, research_patient as rp WHERE p.id=e.patient_id AND p.health_id=rp.health_id) as delta_days,  # to remove
    DATE_FORMAT(e.encounter_date, '%Y-%m-%d') as encounter_date, # to remove
    DATE_FORMAT((SELECT DATE_ADD(e.encounter_date,  INTERVAL delta_days DAY) ), '%Y-%m-%d') as encounter_date_mod,
    (SELECT YEAR(DATE_ADD(encounter_date,  INTERVAL delta_days DAY))) as encounter_year_mod,
      (SELECT MONTH(DATE_ADD(encounter_date,  INTERVAL delta_days DAY))) as encounter_month_mod,
    (SELECT DAY(DATE_ADD(encounter_date,  INTERVAL delta_days DAY))) as encounter_day_mod,
    (SELECT p.dob FROM cc_patient as p WHERE p.id=e.patient_id) as patient_dob,
    (SELECT DATE_ADD(p.dob,  INTERVAL delta_days DAY) FROM cc_patient as p WHERE p.id=e.patient_id) as patient_dob_mod,
    (SELECT DATEDIFF(e.encounter_date, p.dob)/365 FROM cc_patient as p WHERE p.id=e.patient_id) as age_at_encounter,
    e.encounter_date as original_encounter_date,
    (SELECT DATE_ADD(p.created_on,  INTERVAL delta_days DAY) FROM cc_patient as p WHERE p.id=e.patient_id) as patient_registered_on_mod, 
        (SELECT rp.research_id FROM cc_patient as p, research_patient as rp WHERE p.id=e.patient_id AND p.health_id=rp.health_id) as patient_id, 
    (SELECT rl.research_id FROM research_location as rl, cc_patient as p, research_patient as rp WHERE p.id=e.patient_id AND p.health_id=rp.health_id AND rl.location_id=p.location_id) as location, 
    (SELECT p.gender FROM cc_patient as p WHERE p.id=e.patient_id) as patient_gender, 

    (SELECT p.household_id FROM cc_patient as p WHERE p.id=e.patient_id) as hohh_id,  # to remove
    (SELECT rp.research_id FROM cc_patient as p, research_patient as rp WHERE p.id=hohh_id AND p.health_id=rp.health_id) as hohh, 
    (SELECT p.mother_id FROM cc_patient as p WHERE p.id=e.patient_id) as pmother_id,  # to remove
    (SELECT rp.research_id FROM cc_patient as p, research_patient as rp WHERE p.id=pmother_id AND p.health_id=rp.health_id) as mother,
    (SELECT rchw.research_id FROM cc_patient as p, research_chw as rchw WHERE p.id=e.patient_id AND rchw.chw_id=p.chw_id) as chw, 

    (SELECT bir.clinic_delivery FROM cc_birthrpt as bir, cc_ccrpt as cc WHERE bir.ccreport_ptr_id=cc.id and cc.encounter_id=e.id) as bir_delivered_in_hf, 
    (SELECT bir.weight FROM cc_birthrpt as bir, cc_ccrpt as cc WHERE bir.ccreport_ptr_id=cc.id and cc.encounter_id=e.id) as bir_weight, 

    (SELECT p.status FROM cc_patient as p WHERE p.id=e.patient_id) as patient_status, 
      (SELECT dr.death_date FROM cc_deathrpt as dr, cc_ccrpt as cc WHERE dr.ccreport_ptr_id=cc.id and cc.encounter_id=e.id) as death_date, 
    (SELECT DATE_ADD(dr.death_date,  INTERVAL delta_days DAY) FROM cc_deathrpt as dr, cc_ccrpt as cc WHERE dr.ccreport_ptr_id=cc.id and cc.encounter_id=e.id) as death_date_mod, 
    (SELECT sbmc.incident_date FROM cc_sbmcrpt as sbmc, cc_ccrpt as cc WHERE sbmc.ccreport_ptr_id=cc.id and cc.encounter_id=e.id) as sbmc_date, 
    (SELECT DATE_ADD(sbmc.incident_date,  INTERVAL delta_days DAY) FROM cc_sbmcrpt as sbmc, cc_ccrpt as cc WHERE sbmc.ccreport_ptr_id=cc.id and cc.encounter_id=e.id) as sbmc_date_mod, 
    (SELECT sbmc.type FROM cc_sbmcrpt as sbmc, cc_ccrpt as cc WHERE sbmc.ccreport_ptr_id=cc.id and cc.encounter_id=e.id) as sbmc_type,
  CASE WHEN EXTRACT(HOUR FROM e.encounter_date)=12 AND EXTRACT(MINUTE FROM e.encounter_date)=0 AND EXTRACT(SECOND FROM e.encounter_date)=0 THEN 'D' ELSE 'S' END AS source
FROM cc_encounter as e
UNION SELECT 
NULL, # Seq
CONCAT(ccd.first_name, " ", ccd.last_name),
(SELECT rccd.days FROM research_deadperson as rccd WHERE ccd.id=rccd.dead_id) as dead_delta_days,  # to remove, #delta
NULL, # encounter_date
NULL, # encounter_date_mod
NULL, # encounter year
NULL, #encountermonth
NULL, # encounter day
 ccd.dob as patient_dob,
 (SELECT DATE_ADD(ccd.dob,  INTERVAL dead_delta_days DAY) ) as patient_dob_mod,
NULL, # age at enc
NULL, # original enc
NULL, # patient registered on
(SELECT rccd.research_id FROM research_deadperson as rccd WHERE rccd.dead_id=ccd.id) as patient_id, 
(SELECT rl.research_id FROM research_location as rl WHERE rl.location_id=ccd.location_id) as location, 
ccd.gender,
ccd.household_id as hohh_id, # to remove
 (SELECT rccd.research_id FROM cc_patient as p, research_patient as rccd WHERE p.id=hohh_id AND p.health_id=rccd.health_id) as hohh, 
NULL, # mother id
NULL, #mother
(SELECT rchw.research_id FROM research_chw as rchw WHERE rchw.chw_id=ccd.chw_id) as chw, 
NULL, # bir delivered
NULL, #bir weight
-1,
ccd.dod as death_date,
(SELECT DATE_ADD(ccd.dod,  INTERVAL dead_delta_days DAY) ) as death_date_mod,
NULL, # sbmc date
NULL, # sbmc date mod
NULL, # sbmc type,
NULL # source
FROM cc_dead_person as ccd;

ALTER TABLE cc_export_tmp DROP Seq;
ALTER TABLE cc_export_tmp DROP patient_dob;
ALTER TABLE cc_export_tmp DROP patient_name;
ALTER TABLE cc_export_tmp DROP delta_days;
ALTER TABLE cc_export_tmp DROP encounter_date;
ALTER TABLE cc_export_tmp DROP encounter_year_mod;
ALTER TABLE cc_export_tmp DROP encounter_month_mod;
ALTER TABLE cc_export_tmp DROP encounter_day_mod;
ALTER TABLE cc_export_tmp DROP original_encounter_date;
ALTER TABLE cc_export_tmp DROP death_date;
ALTER TABLE cc_export_tmp DROP sbmc_date;
ALTER TABLE cc_export_tmp DROP hohh_id;
ALTER TABLE cc_export_tmp DROP mother_id;
ALTER TABLE cc_export_tmp DROP patient_registered_on_mod;
DELETE FROM cc_export_tmp WHERE encounter_date_mod >= DATE_SUB(NOW(), INTERVAL 30 DAY);


set @oFilename = "";
PREPARE stmt1 FROM 'SELECT CONCAT("/tmp/", substring(research_id, 1,2), "_Form_A_", DATE_FORMAT(NOW(), "%Y-%m-%d"), ".csv") INTO @oFilename  FROM research_patient limit 1';
EXECUTE stmt1;
set @oOutput = CONCAT('SELECT * INTO OUTFILE "', @oFilename, '"  FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY \'"\' LINES TERMINATED BY \'\n\' FROM cc_export_tmp');
PREPARE stmt2 FROM @oOutput;         
EXECUTE stmt2;
DEALLOCATE PREPARE stmt1;
DEALLOCATE PREPARE stmt2;

DROP TABLE IF EXISTS `cc_export_tmp`;
