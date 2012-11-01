// TODO: move culling to camera, evaluate globals, move events to responder model, fonts, think about updates and reshapes (multiple times, wrong size), interleaved arrays

#ifndef CORE3D_HEADER
#define CORE3D_HEADER 1




enum {
	kIntersecting = -1,
	kOutside,
	kInside
};

typedef enum {
	kXAxis = 0,				//00
	kYAxis = 1,				//01
	kZAxis = 2,				//10
	kDisabledAxis = 3,		//11
	
							//3. 2. 1.
	kYXZRotation = 33,		//10 00 01		
	kXYZRotation = 36,		//10 01 00
	kDisabledRotation = 63	//11 11 11
} axisConfigurationEnum;

typedef enum {
	kNoFiltering = 0,
	kPCFHardware,
	kPCF4,
	kPCF16,
	kPCSS
} shadowFilteringEnum;

typedef enum {
	kNoSlowmo = 0,
	kNitroSlowmo,
    kWeaponSlowmo,
} slowmoEnum;

typedef enum {
	kNoShadow = 0,
	kShipOnly,
//	kEverything,
} shadowModeEnum;

typedef enum {
	kShadowQualityLow = 0,
	kShadowQualityHigh,
} shadowQualityEnum;

typedef enum {
	kVendorUnknown = 0,
	kVendorATI,
	kVendorNVIDIA,
	kVendorMesa,
} gpuVendorEnum;

typedef struct _vertex {
	GLfloat		x,y,z,u,v;
} vertex;


typedef struct _v3 { GLfloat		x,y,z; } v3;
typedef struct _v4 { GLfloat		x,y,z,w; } v4;

typedef struct _Info
{
	NSArray *commandLineParameters;
	CFTimeInterval frameDiff;
	uint64_t frame;
    GLuint VRAM;
    GLuint defaultVAOName;
	uint32_t renderedFaces;
	uint32_t visitedNodes;
	uint32_t drawCalls;
    uint16_t fps;
    uint16_t pvsCells;
    uint8_t gpuSuckynessClass;
    uint8_t maxMultiSamples;
	gpuVendorEnum gpuVendor; 
    BOOL properOpenGL;
    BOOL modernOpenGL;
    BOOL online;
#ifdef TARGET_OS_IPHONE
    UIInterfaceOrientation interfaceOrientation;
#endif
} Info;

extern Info globalInfo;


#define AXIS_CONFIGURATION(x,y,z) ((axisConfigurationEnum)(x | y << 2 | z << 4))




#define kSoundEnabledKey @"soundEnabled"
#define kSoundVolumeKey @"soundVolume"
#define kShadowsEnabledKey @"shadowsEnabled"
#define kShadowSizeKey @"shadowSize"
#define kShadowFilteringKey @"shadowFiltering"
#define kFullscreenResolutionFactorKey @"fullscreenResolutionFactor"
#define kOutlinesKey @"outlines"
#define kOutlinesColorKey @"outlinesColor"
#define kFullscreenKey @"fullscreen"
#define kFsaaKey @"fsaa"
#define kTextureQualityKey @"textureQuality"
#define kMusicVolumeKey @"musicVolume"
#define kMusicEnabledKey @"musicEnabled"



#if defined(__cplusplus) && defined(__OBJC__)

    typedef struct _TriangleIntersectionInfo {
        BOOL intersects;
        //	vector3f v1, v2, v3;
        //	vector3f o1, o2, o3;
        vector3f normal, point;
        float depth;
    } TriangleIntersectionInfo;

    typedef struct _Material {
        char activeLightIndices[2];
        vector4f color;
        vector4f specular;
        float shininess;
        vector4f emission;
        vector4f lightModelAmbient;
    } Material;

    typedef struct _Settings {
        BOOL disableCulling;
        BOOL disableTex;
        BOOL disableVBLSync;
        BOOL doWireframe;
        BOOL displayFPS;
        
        
        slowmoEnum slowMotion;
        shadowModeEnum shadowMode;
        shadowFilteringEnum shadowFiltering;
        uint8_t	shadowSize;
        uint8_t	outlineMode;
        vector4f outlineColor;
        
    #ifndef DISABLE_SOUND
        BOOL soundEnabled;
        float soundVolume;
    #endif
    } Settings;

    extern Material globalMaterial;
    extern Settings globalSettings;

    #ifdef TARGET_OS_IPHONE
        #define IMG_EXTENSIONS [NSArray arrayWithObjects:@"pvrtc", @"png", @"jpg", nil]
        #define SND_EXTENSIONS [NSArray arrayWithObjects:@"caf", @"mp3", nil]
        extern UIAccelerationValue		accelerometerGravity[3];
        extern UIAccelerationValue		accelerometerChanges[3];
        #define SCENE_CONFIG_IPHONE 1
        #define SOUND_TYPE SystemSoundID
    #else
        #define IMG_EXTENSIONS [NSArray arrayWithObjects:@"dds", @"jp2", @"png", @"jpg", nil]
        #define SND_EXTENSIONS [NSArray arrayWithObjects:@"wav", @"mp3", nil]

        #ifdef SDL
            #define SOUND_TYPE Mix_Chunk*
        #else
            #define SOUND_TYPE NSSound*
        #endif
    #endif

    #import "StateUtilities.h"

	@class SceneNode;
	@class Light;
	@class RenderPass;
	CUSTOM_MUTABLE_ARRAY(SceneNode)
	CUSTOM_MUTABLE_ARRAY(Light)
	CUSTOM_MUTABLE_ARRAY(RenderPass)

    #ifndef DISABLE_SOUND
        #import "SoundBuffer.h"
    #endif
    #import "SceneNode.h"
    #import "VBO.h"
    #import "Camera.h"
    #import "Light.h"
    #import "Texture.h"
    #import "RenderTarget.h"
    #import "RenderPass.h"
    #import "FBO.h"
    #import "Simulation.h"
    #import "Utilities.h"
    #import "Mesh.h"
    #import "Shader.h"
    #import "Scene.h"
    #ifndef DISABLE_SOUND
        #import "MusicManager.h"
    #endif
    #import "ShaderNode.h"
    #import "SpriteNode.h"
    #import "DynamicNode.h"
    #import "BatchingTextureNode.h"



    #import "CollideableMeshBullet.h"
    #import "CollideableSceneNode.h"




    extern NSMutableArray *pressedKeys;
    extern NSMutableArray *activeTouches;
    extern BOOL wasShaking;
    extern Scene *scene;
    extern Camera *currentCamera;
    extern RenderPass *currentRenderPass;
    extern Shader *currentShader;
    extern Texture *currentTexture;
    extern VBO *currentVBO;

    #define PVS_RESOLUTION 1000

#endif
#endif

