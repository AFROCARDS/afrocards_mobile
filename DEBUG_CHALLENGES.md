# 🔍 DEBUG: Erreur 404 Chargement des Challenges

## 🎯 Problème Identifié

**Erreur:** `Exception: Erreur: 404`

**Cause Probable:** Double `/api` dans l'URL
- Frontend appelle: `/api/challenges-sponsorises/active`
- BaseURL inclut déjà: `/api`
- **URL générée:** `http://10.0.2.2:5000/api/api/challenges-sponsorises/active` ❌

**Correction Appliquée:**
- ✅ Ajouté endpoints constants dans `ApiEndpoints.dart`
- ✅ Utilisé constants au lieu de chemins en dur
- ✅ Suppression du double `/api`

---

## 🔧 Comment Lire les Logs de Debug

### Sur VS Code / Android Studio

1. **Ouvrir le Debug Console**
   - VS Code: Terminal → Afficher le terminal integré
   - Android Studio: Logcat tab (en bas)

2. **Filtrer les logs**
   - Chercher: `=== CHARGEMENT CHALLENGES` (début)
   - Ou: `Erreur chargement challenges` (erreur)

### Exemple de Logs Réussis

```
🚀 === CHARGEMENT CHALLENGES SPONSORISÉS ===
📱 Token: eyJhbGciOiJIUzI1NiI...
🔗 BaseURL: http://10.0.2.2:5000/api
🌐 URL complète: http://10.0.2.2:5000/api/challenges-sponsorises/active
📊 Status Code: 200
📦 Body (1250 chars): {"data":[...],...}
✅ Data reçue: 6 challenges
✅ Challenges parsées: 6
```

### Exemple de Logs d'Erreur 404

```
🚀 === CHARGEMENT CHALLENGES SPONSORISÉS ===
📱 Token: eyJhbGciOiJIUzI1NiI...
🔗 BaseURL: http://10.0.2.2:5000/api
🌐 URL complète: http://10.0.2.2:5000/api/challenges-sponsorises/active
📊 Status Code: 404
📦 Body: {"error":"Not Found"}
❌ ERREUR HTTP 404
📄 Response: {"error":"Not Found"}
```

---

## ✅ Points à Vérifier pour le Backend

### 1. **Vérifier que les routes sont enregistrées**

**Fichier:** `src/routes/index.js`

```javascript
// ✅ Doit contenir:
router.use('/challenges-sponsorises', challengeSponsoriseRoutes);
```

### 2. **Vérifier l'endpoint GET /active**

**Fichier:** `src/routes/challengeSponsorise.routes.js`

```javascript
/**
 * @route   GET /api/challenges-sponsorises/active
 * @access  Public
 * @desc    Get all active sponsored challenges
 */
router.get('/active', getAllActive);
```

### 3. **Vérifier le controller**

**Fichier:** `src/controllers/challengeSponsorise.controller.js`

```javascript
const getAllActive = async (req, res) => {
  try {
    const challenges = await ChallengeSponsorise.findAll({
      where: { statut: 'actif' },
      include: [{ model: Partenaire }],
    });
    res.json({ success: true, data: challenges });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = { getAllActive };
```

### 4. **Vérifier la base de données**

```sql
-- S'assurer que les données existent:
SELECT * FROM challenges_sponsorises WHERE statut = 'actif';

-- Si vide, exécuter le seeder:
npm run seed:challenges
```

---

## 🧪 Test Manual de l'API

### Avec Postman / Thunder Client

**URL:**
```
GET http://10.0.2.2:5000/api/challenges-sponsorises/active
```

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <YOUR_TOKEN>
```

**Expected Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "idChallenge": 1,
      "idPartenaire": 1,
      "titre": "Google Search Master",
      "description": "Test your Google knowledge",
      "recompense": "500 XP, 100 Coins",
      "dateDebut": "2026-03-11T00:00:00Z",
      "dateFin": "2026-03-21T00:00:00Z",
      "statut": "actif",
      "Partenaire": {
        "idPartenaire": 1,
        "entreprise": "Google",
        "secteur": "Technologie"
      }
    },
    ...
  ]
}
```

---

## 📋 Checklist de Débogage

- [ ] Backend server running: `npm start`
- [ ] Seeder executed: `npm run seed:challenges`
- [ ] Database contains challenges: `SELECT COUNT(*) FROM challenges_sponsorises`
- [ ] Routes loaded: Check `src/routes/index.js` has `challengeSponsoriseRoutes`
- [ ] API responds: Test with Postman/Thunder Client
- [ ] Frontend token valid: Check token is not NULL or expired
- [ ] Correct URL: Check URL doesn't have double `/api`
- [ ] Firebase/Network config: Check 10.0.2.2 is correct for emulator

---

## 🎯 Logs de Soumission (challenge_game_screen)

### Succès (200)
```
🚀 === SOUMISSION RÉSULTAT CHALLENGE ===
🎯 Challenge ID: 1
📊 Score: 7 / 10
📱 Token: eyJhbGc...
🌐 URL: http://10.0.2.2:5000/api/challenges-sponsorises/submit-result
📊 Response Status: 200
📦 Response Body: {"success":true,"data":{"trophy":{"id":1,"name":"Trophy_1_Google"}}
✅ Résultat reçu: {"trophy":{"id":1,"name":"Trophy_1_Google"}}
🏆 Trophy? {"id":1,"name":"Trophy_1_Google"}
```

### Erreur (400/401/500)
```
❌ === ERREUR SOUMISSION CHALLENGE ===
📊 Response Status: 400
📄 Response: {"error":"Invalid request body"}
❌ Exception: Exception: Erreur HTTP: 400
```

---

## 🚀 Prochaines étapes

1. **Vérifier les logs** après avoir lancé l'app
2. **Chercher** `=== CHARGEMENT CHALLENGES` dans la console
3. **Partager** les logs complets avec URL exacte et status code
4. **Tester l'API** directement avec Postman
5. **Vérifier** que `npm run seed:challenges` a fonctionné

---

**Format pour rapporter le bug:**
```
Erreur: [Copier le texte d'erreur exact]
URL: [Copier depuis le log]
Status: [Copier le code HTTP]
Backend: [En cours/Arrêté/Erreur]
```
