using System;
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using KochiHomecoming.Interaction;
using KochiHomecoming.Player;
using KochiHomecoming.UI;
using KochiHomecoming.Vehicles;

namespace KochiHomecoming.Editor
{
    public static class HomecomingSceneSetup
    {
        public const string ScenePath = "Assets/Scenes/Homecoming.unity";
        private const string MaterialFolder = "Assets/Generated/Materials";

        private static Material asphalt;
        private static Material lanePaint;
        private static Material pavement;
        private static Material concrete;
        private static Material cream;
        private static Material paleYellow;
        private static Material terracotta;
        private static Material glass;
        private static Material darkMetal;
        private static Material wood;
        private static Material foliage;
        private static Material trunk;
        private static Material signboard;
        private static Material warmWhite;
        private static Material playerClothes;
        private static Material playerSkin;
        private static Material carPaint;
        private static Material rubber;
        private static Material redPaint;
        private static Material bluePaint;

        [MenuItem("Kochi Homecoming/Generate Opening Street")]
        public static void GenerateDemoScene()
        {
            EnsureFolders();
            CreateMaterials();

            Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            scene.name = "Homecoming";

            ConfigureLighting();
            BuildGroundAndRoad();
            BuildStreet();
            BuildFamilyHome();
            BuildStreetFurniture();
            GameObject player = BuildPlayer();
            VehicleDriveController vehicle = BuildVehicle();
            HomecomingMissionSystem missionSystem = new GameObject("Mission System")
                .AddComponent<HomecomingMissionSystem>();
            BasicWorldInteractable gate = CreateBox("Family Home Gate Interaction",
                new Vector3(8.4f, 1.05f, 28f), new Vector3(0.25f, 1.9f, 2.6f),
                darkMetal, true).AddComponent<BasicWorldInteractable>();
            gate.Configure("Inspect the gate", "You pause at the entrance to the family home.",
                "Explore the street and get familiar with the controls.", missionSystem);

            GameObject cameraObject = new GameObject("Main Camera", typeof(Camera), typeof(AudioListener));
            cameraObject.tag = "MainCamera";
            Camera camera = cameraObject.GetComponent<Camera>();
            camera.fieldOfView = 62f;
            camera.nearClipPlane = 0.08f;
            camera.farClipPlane = 220f;
            camera.allowHDR = false;
            camera.allowMSAA = true;
            OrbitCamera orbit = cameraObject.AddComponent<OrbitCamera>();
            orbit.SetTarget(player.transform);
            orbit.enabled = true;

            ThirdPersonMotor motor = player.GetComponent<ThirdPersonMotor>();
            GameObject hudRoot = new GameObject("Mobile HUD Controller");
            MobileHUD hud = hudRoot.AddComponent<MobileHUD>();
            hud.Configure(motor, player.transform, orbit, vehicle, missionSystem);

            GameObject atmosphere = new GameObject("Atmosphere");
            atmosphere.transform.position = Vector3.zero;

            ConfigurePlayerSettings();
            EnsureBuildSceneList(scene);
            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene, ScenePath);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            Debug.Log("Kochi: Homecoming opening street scene generated at " + ScenePath);
        }

        public static void EnsureGeneratedScene()
        {
            EnsureFolders();
            CreateMaterials();
            if (!File.Exists(ScenePath))
                GenerateDemoScene();
            else
            {
                Scene scene = SceneManager.GetSceneByPath(ScenePath);
                if (!scene.IsValid() || !scene.isLoaded)
                {
                    scene = EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
                }
                EnsureBuildSceneList(scene);
                ConfigurePlayerSettings();
            }
        }

        private static void EnsureFolders()
        {
            CreateFolderIfMissing("Assets", "Scenes");
            CreateFolderIfMissing("Assets", "Generated");
            CreateFolderIfMissing("Assets/Generated", "Materials");
        }

        private static void CreateFolderIfMissing(string parent, string child)
        {
            string path = parent + "/" + child;
            if (!AssetDatabase.IsValidFolder(path))
                AssetDatabase.CreateFolder(parent, child);
        }

        private static void CreateMaterials()
        {
            asphalt = MakeMaterial("Asphalt", new Color(0.105f, 0.12f, 0.125f), 0f, 0.18f);
            lanePaint = MakeMaterial("Warm Lane Paint", new Color(0.89f, 0.82f, 0.62f), 0f, 0.22f);
            pavement = MakeMaterial("Pavement", new Color(0.39f, 0.39f, 0.35f), 0f, 0.25f);
            concrete = MakeMaterial("Boundary Concrete", new Color(0.61f, 0.58f, 0.5f), 0f, 0.22f);
            cream = MakeMaterial("Kerala Plaster Cream", new Color(0.73f, 0.65f, 0.49f), 0f, 0.27f);
            paleYellow = MakeMaterial("Old Shop Paint", new Color(0.52f, 0.37f, 0.22f), 0f, 0.27f);
            terracotta = MakeMaterial("Terracotta Roof", new Color(0.33f, 0.115f, 0.075f), 0f, 0.3f);
            glass = MakeMaterial("Smoky Window Glass", new Color(0.115f, 0.19f, 0.2f), 0.22f, 0.17f);
            darkMetal = MakeMaterial("Aged Dark Metal", new Color(0.095f, 0.115f, 0.11f), 0f, 0.42f);
            wood = MakeMaterial("Weathered Wood", new Color(0.23f, 0.115f, 0.055f), 0f, 0.32f);
            foliage = MakeMaterial("Deep Tropical Green", new Color(0.075f, 0.20f, 0.095f), 0f, 0.29f);
            trunk = MakeMaterial("Palm Trunk", new Color(0.29f, 0.18f, 0.10f), 0f, 0.55f);
            signboard = MakeMaterial("Faded Signboard", new Color(0.20f, 0.11f, 0.075f), 0f, 0.32f);
            warmWhite = MakeMaterial("Warm White", new Color(0.83f, 0.77f, 0.62f), 0f, 0.2f);
            playerClothes = MakeMaterial("Vivek Charcoal Shirt", new Color(0.105f, 0.15f, 0.17f), 0f, 0.28f);
            playerSkin = MakeMaterial("Skin", new Color(0.48f, 0.29f, 0.19f), 0f, 0.35f);
            carPaint = MakeMaterial("Muted Deep Green Car", new Color(0.065f, 0.19f, 0.14f), 0.25f, 0.22f);
            rubber = MakeMaterial("Tyre Rubber", new Color(0.025f, 0.03f, 0.028f), 0f, 0.63f);
            redPaint = MakeMaterial("Brake Red", new Color(0.55f, 0.075f, 0.035f), 0f, 0.26f);
            bluePaint = MakeMaterial("Faded Blue Paint", new Color(0.14f, 0.25f, 0.31f), 0f, 0.29f);
        }

        private static Material MakeMaterial(string name, Color color, float metallic, float smoothness)
        {
            string path = MaterialFolder + "/" + name.Replace(" ", "_") + ".mat";
            Material material = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (material == null)
            {
                Shader shader = Shader.Find("Standard");
                if (shader == null) shader = Shader.Find("Universal Render Pipeline/Lit");
                material = new Material(shader) { name = name };
                AssetDatabase.CreateAsset(material, path);
            }
            material.color = color;
            if (material.HasProperty("_Metallic")) material.SetFloat("_Metallic", metallic);
            if (material.HasProperty("_Glossiness")) material.SetFloat("_Glossiness", smoothness);
            EditorUtility.SetDirty(material);
            return material;
        }

        private static void ConfigureLighting()
        {
            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Flat;
            RenderSettings.ambientLight = new Color(0.48f, 0.47f, 0.43f);
            RenderSettings.fog = true;
            RenderSettings.fogColor = new Color(0.48f, 0.49f, 0.46f);
            RenderSettings.fogMode = FogMode.ExponentialSquared;
            RenderSettings.fogDensity = 0.0028f;

            GameObject sun = new GameObject("Late Afternoon Sun", typeof(Light));
            Light light = sun.GetComponent<Light>();
            light.type = LightType.Directional;
            light.color = new Color(1f, 0.83f, 0.66f);
            light.intensity = 1.35f;
            light.shadows = LightShadows.Soft;
            sun.transform.rotation = Quaternion.Euler(42f, -28f, 0f);

            QualitySettings.vSyncCount = 0;
            QualitySettings.antiAliasing = 2;
            QualitySettings.shadowDistance = 75f;
            QualitySettings.shadows = ShadowQuality.All;
        }

        private static void BuildGroundAndRoad()
        {
            CreateBox("Terrain Base", new Vector3(0f, -0.32f, 0f), new Vector3(300f, 0.5f, 220f), foliage, true);
            CreateBox("Main Asphalt Road", new Vector3(0f, -0.035f, 0f), new Vector3(14f, 0.12f, 126f), asphalt, true);
            CreateBox("West Footpath", new Vector3(-8.55f, 0.025f, 0f), new Vector3(3.1f, 0.22f, 126f), pavement, true);
            CreateBox("East Footpath", new Vector3(8.55f, 0.025f, 0f), new Vector3(3.1f, 0.22f, 126f), pavement, true);
            CreateBox("West Kerb", new Vector3(-7.05f, 0.12f, 0f), new Vector3(0.22f, 0.32f, 126f), concrete, true);
            CreateBox("East Kerb", new Vector3(7.05f, 0.12f, 0f), new Vector3(0.22f, 0.32f, 126f), concrete, true);

            for (int z = -58; z <= 58; z += 8)
                CreateBox("Broken Centre Line", new Vector3(0f, 0.035f, z), new Vector3(0.12f, 0.018f, 3.4f), lanePaint, false);

            for (int z = -49; z <= 49; z += 14)
            {
                CreateBox("Road Edge Dash West", new Vector3(-6.55f, 0.034f, z), new Vector3(0.07f, 0.015f, 2.2f), lanePaint, false);
                CreateBox("Road Edge Dash East", new Vector3(6.55f, 0.034f, z), new Vector3(0.07f, 0.015f, 2.2f), lanePaint, false);
            }

            // Side-road mouths create a less corridor-like street layout.
            CreateBox("Side Road North", new Vector3(0f, -0.03f, 59f), new Vector3(45f, 0.11f, 12f), asphalt, true);
            CreateBox("Side Road South", new Vector3(0f, -0.03f, -59f), new Vector3(45f, 0.11f, 12f), asphalt, true);
        }

        private static void BuildStreet()
        {
            int index = 0;
            for (int z = -48; z <= 48; z += 16)
            {
                BuildShopfront(-1, z, index++);
                BuildShopfront(1, z + 4, index++);
            }

            // Low walls, drains and small forecourt details break up the road edge.
            for (int z = -53; z <= 53; z += 7)
            {
                CreateBox("Drain Cover West", new Vector3(-7.35f, 0.145f, z), new Vector3(0.32f, 0.035f, 1.2f), darkMetal, false);
                CreateBox("Drain Cover East", new Vector3(7.35f, 0.145f, z), new Vector3(0.32f, 0.035f, 1.2f), darkMetal, false);
            }
        }

        private static void BuildShopfront(int side, float z, int index)
        {
            float centerX = side * (15.7f + (index % 2) * 0.6f);
            float widthX = 8.4f;
            float depthZ = 10f + (index % 3);
            float height = 7.4f + (index % 4) * 1.25f;
            float frontX = centerX - side * widthX * 0.5f;
            Material facade = (index % 3 == 0) ? paleYellow : cream;
            CreateBox("Shop Building " + index, new Vector3(centerX, height * 0.5f, z),
                new Vector3(widthX, height, depthZ), facade, true);

            CreateBox("Flat Roof Parapet " + index,
                new Vector3(centerX, height + 0.18f, z),
                new Vector3(widthX + 0.25f, 0.35f, depthZ + 0.3f), concrete, false);

            // Three detailed bays across the road-facing side: glass, frame and lintel.
            for (int bay = -1; bay <= 1; bay++)
            {
                float paneZ = z + bay * 2.6f;
                CreateBox("Ground Glass Bay", new Vector3(frontX - side * 0.075f, 1.55f, paneZ),
                    new Vector3(0.075f, 1.65f, 1.85f), glass, false);
                CreateBox("Upper Glass Bay", new Vector3(frontX - side * 0.08f, 4.75f, paneZ),
                    new Vector3(0.08f, 1.6f, 1.8f), glass, false);
                CreateBox("Window Sill", new Vector3(frontX - side * 0.14f, 0.69f, paneZ),
                    new Vector3(0.24f, 0.14f, 2.05f), concrete, false);
                CreateBox("Upper Window Sill", new Vector3(frontX - side * 0.15f, 3.82f, paneZ),
                    new Vector3(0.25f, 0.13f, 2.05f), concrete, false);
                CreateBox("Upper Balcony Rail", new Vector3(frontX - side * 0.42f, 3.3f, paneZ),
                    new Vector3(0.12f, 0.08f, 2.4f), darkMetal, false);
                for (int rail = -2; rail <= 2; rail++)
                    CreateBox("Balcony Railing", new Vector3(frontX - side * 0.42f, 3.03f, paneZ + rail * 0.43f),
                        new Vector3(0.08f, 0.54f, 0.07f), darkMetal, false);
            }

            CreateBox("Faded Shop Sign " + index,
                new Vector3(frontX - side * 0.12f, 2.75f, z),
                new Vector3(0.22f, 0.58f, depthZ * 0.73f), signboard, false);
            CreateBox("Shop Awning " + index,
                new Vector3(frontX - side * 0.7f, 2.22f, z),
                new Vector3(0.95f, 0.14f, depthZ * 0.84f),
                index % 2 == 0 ? redPaint : bluePaint, false);

            // AC units, rainwater pipes and a second-floor ledge add lived-in detail.
            for (int unit = -1; unit <= 1; unit += 2)
            {
                CreateBox("Outdoor AC Unit", new Vector3(frontX - side * 0.2f, height - 0.8f, z + unit * 3.5f),
                    new Vector3(0.34f, 0.5f, 0.72f), warmWhite, false);
                CreateBox("Rain Pipe", new Vector3(frontX - side * 0.19f, height * 0.5f, z + unit * (depthZ * 0.45f)),
                    new Vector3(0.12f, height, 0.12f), darkMetal, false);
            }
            CreateBox("Footpath Step", new Vector3(frontX - side * 0.85f, 0.18f, z),
                new Vector3(1.1f, 0.28f, depthZ * 0.68f), concrete, false);
        }

        private static void BuildFamilyHome()
        {
            // A Kerala-style family home: deep tiled roof, verandah, columns, boundary wall and metal gate.
            float x = 15.2f;
            float z = 28f;
            CreateBox("Family Home Main Walls", new Vector3(x, 2.35f, z),
                new Vector3(9.2f, 4.7f, 12f), cream, true);
            CreateBox("Front Verandah Floor", new Vector3(9.85f, 0.18f, z),
                new Vector3(2.4f, 0.26f, 8.5f), concrete, true);

            for (int i = -2; i <= 2; i++)
            {
                float columnZ = z + i * 1.7f;
                CreateCylinder("Verandah Pillar", new Vector3(8.85f, 1.45f, columnZ),
                    new Vector3(0.19f, 1.4f, 0.19f), warmWhite, true);
                CreateBox("Pillar Capital", new Vector3(8.85f, 2.92f, columnZ),
                    new Vector3(0.42f, 0.14f, 0.42f), terracotta, false);
            }

            CreateBox("Front Door", new Vector3(10.55f, 1.25f, z),
                new Vector3(0.10f, 2.3f, 1.15f), wood, false);
            CreateBox("Door Frame Top", new Vector3(10.43f, 2.48f, z),
                new Vector3(0.22f, 0.16f, 1.45f), warmWhite, false);

            for (int i = -1; i <= 1; i++)
            {
                float wz = z + i * 3.0f;
                CreateBox("Home Front Window", new Vector3(10.53f, 1.9f, wz),
                    new Vector3(0.10f, 1.28f, 1.5f), glass, false);
                CreateBox("Window Frame Top", new Vector3(10.45f, 2.59f, wz),
                    new Vector3(0.17f, 0.11f, 1.72f), wood, false);
                CreateBox("Window Frame Bottom", new Vector3(10.45f, 1.2f, wz),
                    new Vector3(0.17f, 0.11f, 1.72f), wood, false);
                CreateBox("Window Vertical Mullion", new Vector3(10.45f, 1.9f, wz),
                    new Vector3(0.17f, 1.28f, 0.08f), wood, false);
            }

            CreateBox("Front Gable Accent", new Vector3(10.55f, 4.15f, z),
                new Vector3(0.16f, 0.18f, 12.3f), terracotta, false);

            // A pair of sloping roof planes plus narrow tiles produces a traditional roof silhouette.
            GameObject leftRoof = CreateBox("Terracotta Roof Front Slope",
                new Vector3(12.75f, 5.0f, z), new Vector3(5.9f, 0.25f, 13.6f), terracotta, false);
            leftRoof.transform.rotation = Quaternion.Euler(0f, 0f, 19f);
            GameObject rightRoof = CreateBox("Terracotta Roof Back Slope",
                new Vector3(17.65f, 5.0f, z), new Vector3(5.9f, 0.25f, 13.6f), terracotta, false);
            rightRoof.transform.rotation = Quaternion.Euler(0f, 0f, -19f);

            for (int row = -6; row <= 6; row++)
            {
                float tileZ = z + row * 0.98f;
                GameObject tileA = CreateBox("Roof Tile Ridge A", new Vector3(12.7f, 5.16f, tileZ),
                    new Vector3(5.55f, 0.08f, 0.12f), redPaint, false);
                tileA.transform.rotation = Quaternion.Euler(0f, 0f, 19f);
                GameObject tileB = CreateBox("Roof Tile Ridge B", new Vector3(17.7f, 5.16f, tileZ),
                    new Vector3(5.55f, 0.08f, 0.12f), redPaint, false);
                tileB.transform.rotation = Quaternion.Euler(0f, 0f, -19f);
            }

            CreateBox("Front Boundary Wall Left", new Vector3(8.15f, 0.7f, z - 5.3f),
                new Vector3(0.25f, 1.25f, 3.1f), concrete, true);
            CreateBox("Front Boundary Wall Right", new Vector3(8.15f, 0.7f, z + 5.3f),
                new Vector3(0.25f, 1.25f, 3.1f), concrete, true);
            CreateBox("Gate Left Post", new Vector3(8.25f, 1.1f, z - 1.7f),
                new Vector3(0.38f, 2.2f, 0.38f), warmWhite, true);
            CreateBox("Gate Right Post", new Vector3(8.25f, 1.1f, z + 1.7f),
                new Vector3(0.38f, 2.2f, 0.38f), warmWhite, true);

            for (int side = -1; side <= 1; side += 2)
            {
                float panelZ = z + side * 0.85f;
                CreateBox("Gate Panel Frame", new Vector3(8.30f, 1.05f, panelZ),
                    new Vector3(0.16f, 1.55f, 1.65f), darkMetal, false);
                for (int bar = -4; bar <= 4; bar++)
                    CreateBox("Gate Vertical Bar", new Vector3(8.18f, 1.05f, panelZ + bar * 0.17f),
                        new Vector3(0.10f, 1.45f, 0.045f), warmWhite, false);
            }

            // Planters and broad-leaved greenery soften the hard edges around the porch.
            for (int i = -2; i <= 2; i += 2)
            {
                CreateBox("Porch Planter", new Vector3(9.2f, 0.3f, z + i * 1.7f),
                    new Vector3(0.55f, 0.5f, 0.85f), terracotta, true);
                CreateSphere("Planter Foliage", new Vector3(9.15f, 0.88f, z + i * 1.7f),
                    new Vector3(0.6f, 0.7f, 0.7f), foliage, false);
            }

            CreateBox("House Side Water Tank", new Vector3(19.8f, 4.9f, z - 2.4f),
                new Vector3(1.1f, 1.8f, 1.25f), darkMetal, false);
        }

        private static void BuildStreetFurniture()
        {
            for (int z = -45; z <= 45; z += 18)
            {
                CreateCylinder("Streetlight Pole", new Vector3(-7.9f, 3.3f, z),
                    new Vector3(0.075f, 3.3f, 0.075f), darkMetal, true);
                CreateBox("Streetlight Arm", new Vector3(-7.55f, 6.4f, z),
                    new Vector3(0.72f, 0.08f, 0.08f), darkMetal, false);
                CreateSphere("Streetlight Head", new Vector3(-7.2f, 6.35f, z),
                    new Vector3(0.18f, 0.12f, 0.22f), warmWhite, false);

                CreateCylinder("Opposite Streetlight Pole", new Vector3(7.9f, 3.1f, z + 7f),
                    new Vector3(0.07f, 3.1f, 0.07f), darkMetal, true);
                CreateBox("Opposite Streetlight Arm", new Vector3(7.58f, 6.0f, z + 7f),
                    new Vector3(0.65f, 0.07f, 0.07f), darkMetal, false);
                CreateSphere("Opposite Streetlight Head", new Vector3(7.28f, 5.98f, z + 7f),
                    new Vector3(0.17f, 0.11f, 0.2f), warmWhite, false);
            }

            for (int z = -42; z <= 42; z += 21)
            {
                CreatePalmTree(-9.8f, z, 0.9f + (Mathf.Abs(z) % 3) * 0.08f);
                if (z != 21 && z != -21) CreatePalmTree(9.9f, z + 7f, 0.85f);
            }

            // Simple road-side bus shelter and bench provide scale and environmental storytelling.
            CreateBox("Bus Stop Canopy", new Vector3(-8.7f, 3.0f, -24f),
                new Vector3(2.3f, 0.16f, 4.2f), terracotta, false);
            for (int i = -1; i <= 1; i += 2)
                CreateBox("Bus Stop Support", new Vector3(-8.7f, 1.55f, -24f + i * 1.65f),
                    new Vector3(0.10f, 2.8f, 0.10f), darkMetal, true);
            CreateBox("Bus Stop Bench Seat", new Vector3(-8.65f, 0.72f, -24f),
                new Vector3(0.55f, 0.12f, 2.1f), wood, true);
            CreateBox("Bus Stop Bench Back", new Vector3(-8.65f, 1.15f, -24f),
                new Vector3(0.12f, 0.75f, 2.1f), wood, false);
        }

        private static void CreatePalmTree(float x, float z, float scale)
        {
            GameObject root = new GameObject("Coconut Palm");
            root.transform.position = new Vector3(x, 0f, z);
            float height = 7.2f * scale;
            GameObject trunkObj = CreateCylinder("Palm Trunk", new Vector3(x, height * 0.47f, z),
                new Vector3(0.2f * scale, height * 0.51f, 0.2f * scale), trunk, false);
            trunkObj.transform.rotation = Quaternion.Euler(0f, 0f, (x > 0 ? -1f : 1f) * 7f);
            for (int i = 0; i < 8; i++)
            {
                float angle = i * 45f;
                GameObject frond = CreateCapsule("Palm Frond",
                    new Vector3(x, height, z) + Quaternion.Euler(0f, angle, 0f) * new Vector3(0f, -0.2f, 1.75f * scale),
                    new Vector3(0.12f * scale, 0.88f * scale, 0.18f * scale), foliage, false);
                frond.transform.rotation = Quaternion.Euler(-18f, angle, 42f);
            }
            for (int i = 0; i < 3; i++)
                CreateSphere("Coconut", new Vector3(x + (i - 1) * 0.15f, height - 0.45f, z + 0.1f),
                    new Vector3(0.17f, 0.17f, 0.17f), trunk, false);
        }

        private static GameObject BuildPlayer()
        {
            GameObject root = new GameObject("Vivek", typeof(CharacterController));
            root.transform.position = new Vector3(0f, 0.02f, 0f);
            CharacterController controller = root.GetComponent<CharacterController>();
            controller.height = 1.8f;
            controller.radius = 0.31f;
            controller.center = new Vector3(0f, 0.9f, 0f);
            controller.slopeLimit = 45f;
            controller.stepOffset = 0.28f;
            controller.skinWidth = 0.035f;

            CreatePersonCapsule(root.transform, "Torso", new Vector3(0f, 1.08f, 0f),
                new Vector3(0.49f, 0.60f, 0.34f), playerClothes);
            CreateSphereChild(root.transform, "Head", new Vector3(0f, 1.77f, 0.015f),
                new Vector3(0.34f, 0.39f, 0.32f), playerSkin);
            CreatePersonCapsule(root.transform, "Left Arm", new Vector3(-0.31f, 1.08f, 0f),
                new Vector3(0.16f, 0.48f, 0.16f), playerClothes).transform.localRotation = Quaternion.Euler(0f, 0f, -10f);
            CreatePersonCapsule(root.transform, "Right Arm", new Vector3(0.31f, 1.08f, 0f),
                new Vector3(0.16f, 0.48f, 0.16f), playerClothes).transform.localRotation = Quaternion.Euler(0f, 0f, 10f);
            CreatePersonCapsule(root.transform, "Left Leg", new Vector3(-0.13f, 0.43f, 0f),
                new Vector3(0.17f, 0.40f, 0.18f), darkMetal);
            CreatePersonCapsule(root.transform, "Right Leg", new Vector3(0.13f, 0.43f, 0f),
                new Vector3(0.17f, 0.40f, 0.18f), darkMetal);
            CreateBoxChild(root.transform, "Shirt Collar", new Vector3(0f, 1.48f, 0.015f),
                new Vector3(0.25f, 0.12f, 0.35f), playerClothes);

            root.AddComponent<ThirdPersonMotor>();
            foreach (Transform child in root.GetComponentsInChildren<Transform>(true))
                child.gameObject.isStatic = false;
            return root;
        }

        private static VehicleDriveController BuildVehicle()
        {
            GameObject car = new GameObject("Parked Deep Green Sedan");
            car.transform.position = new Vector3(-4.3f, 0f, 2.5f);
            car.transform.rotation = Quaternion.Euler(0f, 7f, 0f);

            Rigidbody body = car.AddComponent<Rigidbody>();
            body.mass = 1250f;
            BoxCollider hull = car.AddComponent<BoxCollider>();
            hull.center = new Vector3(0f, 0.67f, 0f);
            hull.size = new Vector3(1.9f, 0.88f, 4.15f);

            CreateBoxChild(car.transform, "Sedan Body", new Vector3(0f, 0.68f, 0f),
                new Vector3(1.88f, 0.58f, 4.0f), carPaint);
            CreateBoxChild(car.transform, "Cabin", new Vector3(0f, 1.18f, -0.12f),
                new Vector3(1.48f, 0.67f, 2.0f), bluePaint);
            CreateBoxChild(car.transform, "Front Windshield", new Vector3(0f, 1.35f, 0.88f),
                new Vector3(1.32f, 0.46f, 0.08f), glass);
            CreateBoxChild(car.transform, "Rear Windshield", new Vector3(0f, 1.34f, -1.12f),
                new Vector3(1.27f, 0.42f, 0.08f), glass);
            CreateBoxChild(car.transform, "Bonnet", new Vector3(0f, 0.99f, 1.42f),
                new Vector3(1.72f, 0.15f, 1.0f), carPaint);
            CreateBoxChild(car.transform, "Boot", new Vector3(0f, 0.99f, -1.55f),
                new Vector3(1.7f, 0.15f, 0.72f), carPaint);

            for (int side = -1; side <= 1; side += 2)
            {
                for (int axle = -1; axle <= 1; axle += 2)
                {
                    GameObject wheel = CreateCylinder("Tyre", new Vector3(side * 0.94f, 0.36f, axle * 1.35f),
                        new Vector3(0.33f, 0.16f, 0.33f), rubber, false);
                    wheel.transform.rotation = Quaternion.Euler(0f, 0f, 90f);
                    CreateCylinderChild(car.transform, "Wheel Hub", new Vector3(side * 1.01f, 0.36f, axle * 1.35f),
                        new Vector3(0.17f, 0.04f, 0.17f), concrete, Quaternion.Euler(0f, 0f, 90f));
                }
                CreateBoxChild(car.transform, "Headlamp", new Vector3(side * 0.61f, 0.75f, 2.01f),
                    new Vector3(0.42f, 0.18f, 0.05f), warmWhite);
                CreateBoxChild(car.transform, "Tail Lamp", new Vector3(side * 0.62f, 0.75f, -2.01f),
                    new Vector3(0.38f, 0.16f, 0.05f), redPaint);
                CreateBoxChild(car.transform, "Side Mirror", new Vector3(side * 0.91f, 1.15f, 0.72f),
                    new Vector3(0.2f, 0.12f, 0.25f), darkMetal);
            }

            CreateBoxChild(car.transform, "Front Bumper", new Vector3(0f, 0.40f, 2.05f),
                new Vector3(1.82f, 0.16f, 0.12f), darkMetal);
            CreateBoxChild(car.transform, "Rear Bumper", new Vector3(0f, 0.40f, -2.05f),
                new Vector3(1.82f, 0.16f, 0.12f), darkMetal);

            GameObject exit = new GameObject("Vehicle Exit Point");
            exit.transform.SetParent(car.transform, false);
            exit.transform.localPosition = new Vector3(2.1f, 0.1f, 0f);

            VehicleDriveController controller = car.AddComponent<VehicleDriveController>();
            controller.SetExitPoint(exit.transform);
            foreach (Transform child in car.GetComponentsInChildren<Transform>(true))
                child.gameObject.isStatic = false;
            return controller;
        }

        private static void ConfigurePlayerSettings()
        {
            PlayerSettings.companyName = "Aswin Mohan";
            PlayerSettings.productName = "Kochi Homecoming";
            PlayerSettings.defaultInterfaceOrientation = UIOrientation.LandscapeLeft;
            PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Android, "com.aswinmohan.kochihomecoming");
            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel26;
            PlayerSettings.Android.targetSdkVersion = AndroidSdkVersions.AndroidApiLevelAuto;
            PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
            PlayerSettings.SetScriptingBackend(BuildTargetGroup.Android, ScriptingImplementation.IL2CPP);
            PlayerSettings.stripEngineCode = true;
            PlayerSettings.MTRendering = true;
        }

        private static void EnsureBuildSceneList(Scene scene)
        {
            if (!scene.IsValid()) return;
            EditorBuildSettings.scenes = new[]
            {
                new EditorBuildSettingsScene(ScenePath, true)
            };
        }

        private static GameObject CreateBox(string name, Vector3 position, Vector3 size,
            Material material, bool collider)
        {
            GameObject obj = GameObject.CreatePrimitive(PrimitiveType.Cube);
            obj.name = name;
            obj.transform.position = position;
            obj.transform.localScale = size;
            ApplyMaterial(obj, material);
            if (!collider)
            {
                Collider component = obj.GetComponent<Collider>();
                if (component != null) UnityEngine.Object.DestroyImmediate(component);
            }
            return obj;
        }

        private static GameObject CreateCylinder(string name, Vector3 position, Vector3 size,
            Material material, bool collider)
        {
            GameObject obj = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            obj.name = name;
            obj.transform.position = position;
            obj.transform.localScale = size;
            ApplyMaterial(obj, material);
            if (!collider)
            {
                Collider component = obj.GetComponent<Collider>();
                if (component != null) UnityEngine.Object.DestroyImmediate(component);
            }
            return obj;
        }

        private static GameObject CreateSphere(string name, Vector3 position, Vector3 size,
            Material material, bool collider)
        {
            GameObject obj = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            obj.name = name;
            obj.transform.position = position;
            obj.transform.localScale = size;
            ApplyMaterial(obj, material);
            if (!collider)
            {
                Collider component = obj.GetComponent<Collider>();
                if (component != null) UnityEngine.Object.DestroyImmediate(component);
            }
            return obj;
        }

        private static GameObject CreateCapsule(string name, Vector3 position, Vector3 size,
            Material material, bool collider)
        {
            GameObject obj = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            obj.name = name;
            obj.transform.position = position;
            obj.transform.localScale = size;
            ApplyMaterial(obj, material);
            if (!collider)
            {
                Collider component = obj.GetComponent<Collider>();
                if (component != null) UnityEngine.Object.DestroyImmediate(component);
            }
            return obj;
        }

        private static void ApplyMaterial(GameObject obj, Material material)
        {
            Renderer renderer = obj.GetComponent<Renderer>();
            if (renderer != null && material != null) renderer.sharedMaterial = material;
            obj.isStatic = true;
        }

        private static GameObject CreatePersonCapsule(Transform parent, string name, Vector3 localPosition,
            Vector3 scale, Material material)
        {
            GameObject part = CreateCapsule(name, parent.position + localPosition, scale, material, false);
            part.transform.SetParent(parent, false);
            part.transform.localPosition = localPosition;
            return part;
        }

        private static GameObject CreateSphereChild(Transform parent, string name, Vector3 localPosition,
            Vector3 scale, Material material)
        {
            GameObject part = CreateSphere(name, parent.position + localPosition, scale, material, false);
            part.transform.SetParent(parent, false);
            part.transform.localPosition = localPosition;
            return part;
        }

        private static GameObject CreateBoxChild(Transform parent, string name, Vector3 localPosition,
            Vector3 scale, Material material)
        {
            GameObject part = CreateBox(name, parent.position + localPosition, scale, material, false);
            part.transform.SetParent(parent, false);
            part.transform.localPosition = localPosition;
            return part;
        }

        private static GameObject CreateCylinderChild(Transform parent, string name, Vector3 localPosition,
            Vector3 scale, Material material, Quaternion rotation)
        {
            GameObject part = CreateCylinder(name, parent.position + localPosition, scale, material, false);
            part.transform.SetParent(parent, false);
            part.transform.localPosition = localPosition;
            part.transform.localRotation = rotation;
            return part;
        }
    }
}
