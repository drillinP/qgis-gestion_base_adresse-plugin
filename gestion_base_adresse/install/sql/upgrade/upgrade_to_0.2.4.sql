BEGIN;
--Add default value NOW() to date_modif
ALTER TABLE adresse.voie ALTER COLUMN date_modif SET DEFAULT NOW();
ALTER TABLE adresse.point_adresse ALTER COLUMN date_modif SET DEFAULT NOW();


-- Trigger to save createur and force Now() to date_modif

CREATE OR REPLACE FUNCTION adresse.modif_update()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
BEGIN
    NEW.createur = OLD.createur;
    NEW.date_creation = OLD.date_creation;
    NEW.date_modif = NOW();

    RETURN NEW;
END;
$BODY$;

DROP TRIGGER IF EXISTS update_modif_create ON adresse.voie;
CREATE TRIGGER update_modif_create
    BEFORE UPDATE
    ON adresse.voie
    FOR EACH ROW
    EXECUTE PROCEDURE adresse.modif_update();

DROP TRIGGER IF EXISTS update_modif_create ON adresse.point_adresse;
CREATE TRIGGER update_modif_create
    BEFORE UPDATE
    ON adresse.point_adresse
    FOR EACH ROW
    EXECUTE PROCEDURE adresse.modif_update();

-- Trigger to calculate longueur in voie

CREATE OR REPLACE FUNCTION adresse.longueur_voie()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
BEGIN
    NEW.longueur = ST_Length(NEW.geom);

    RETURN NEW;
END;
$BODY$;

DROP TRIGGER IF EXISTS trigger_longueur ON adresse.voie;
CREATE TRIGGER trigger_longueur
    BEFORE INSERT OR UPDATE
    ON adresse.voie
    FOR EACH ROW
    EXECUTE PROCEDURE adresse.longueur_voie();

-- Add not null constraint

ALTER TABLE adresse.voie ALTER COLUMN sens SET NOT NULL;
ALTER TABLE adresse.voie ALTER COLUMN statut_voie_num SET NOT NULL;
ALTER TABLE adresse.voie ALTER COLUMN statut_voie SET NOT NULL;
ALTER TABLE adresse.voie ALTER COLUMN achat_plaque_voie SET NOT NULL;
ALTER TABLE adresse.voie ALTER COLUMN typologie SET NOT NULL;
ALTER TABLE adresse.voie ALTER COLUMN nom SET NOT NULL;
ALTER TABLE adresse.point_adresse ALTER COLUMN achat_plaque_numero SET NOT NULL;
ALTER TABLE adresse.point_adresse ALTER COLUMN erreur SET NOT NULL;

-- trigger before insert to manage user

CREATE OR REPLACE FUNCTION adresse.modif_createur()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
BEGIN
    IF NEW.createur IS NULL AND NEW.modificateur IS NOT NULL THEN
        NEW.createur = NEW.modificateur;
    ELSIF NEW.createur IS NOT NULL THEN
        NEW.modificateur = NEW.createur;
    END IF;
    NEW.date_creation = NOW();
    NEW.date_modif = NOW();

    RETURN NEW;
END;
$BODY$;

DROP TRIGGER IF EXISTS createur_insert ON adresse.voie;
CREATE TRIGGER createur_insert
    BEFORE INSERT
    ON adresse.voie
    FOR EACH ROW
    EXECUTE PROCEDURE adresse.modif_createur();

DROP TRIGGER IF EXISTS createur_insert ON adresse.point_adresse;
CREATE TRIGGER createur_insert
    BEFORE INSERT
    ON adresse.point_adresse
    FOR EACH ROW
    EXECUTE PROCEDURE adresse.modif_createur();

COMMIT;
