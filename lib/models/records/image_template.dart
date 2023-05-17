import 'dart:ui';

import 'package:uuid/uuid.dart';

class ImageTemplate {
  late final Map data;

  ImageTemplate({required String imageUri, required int width, required int height}) {
    final texture2dUid = const Uuid().v4();
    final quadMeshUid = const Uuid().v4();
    final quadMeshSizeUid = const Uuid().v4();
    final materialId = const Uuid().v4();
    final boxColliderSizeUid = const Uuid().v4();
    data = {
      "Object": {
        "ID": const Uuid().v4(),
        "Components": {
          "ID": const Uuid().v4(),
          "Data": [
            {
              "Type": "FrooxEngine.Grabbable",
              "Data": {
                "ID": const Uuid().v4(),
                "persistent-ID": const Uuid().v4(),
                "UpdateOrder": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "Enabled": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "ReparentOnRelease": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "PreserveUserSpace": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "DestroyOnRelease": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "GrabPriority": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "GrabPriorityWhenGrabbed": {
                  "ID": const Uuid().v4(),
                  "Data": null
                },
                "CustomCanGrabCheck": {
                  "ID": const Uuid().v4(),
                  "Data": {
                    "Target": null
                  }
                },
                "EditModeOnly": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "AllowSteal": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "DropOnDisable": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "ActiveUserFilter": {
                  "ID": const Uuid().v4(),
                  "Data": "Disabled"
                },
                "OnlyUsers": {
                  "ID": const Uuid().v4(),
                  "Data": []
                },
                "Scalable": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "Receivable": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "AllowOnlyPhysicalGrab": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "_grabber": {
                  "ID": const Uuid().v4(),
                  "Data": null
                },
                "_lastParent": {
                  "ID": const Uuid().v4(),
                  "Data": null
                },
                "_lastParentIsUserSpace": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "__legacyActiveUserRootOnly-ID": const Uuid().v4()
              }
            },
            {
              "Type": "FrooxEngine.StaticTexture2D",
              "Data": {
                "ID": texture2dUid,
                "persistent-ID": const Uuid().v4(),
                "UpdateOrder": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "Enabled": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "URL": {
                  "ID": const Uuid().v4(),
                  "Data": "@$imageUri"
                },
                "FilterMode": {
                  "ID": const Uuid().v4(),
                  "Data": "Anisotropic"
                },
                "AnisotropicLevel": {
                  "ID": const Uuid().v4(),
                  "Data": 16
                },
                "Uncompressed": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "DirectLoad": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "ForceExactVariant": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "PreferredFormat": {
                  "ID": const Uuid().v4(),
                  "Data": null
                },
                "MipMapBias": {
                  "ID": const Uuid().v4(),
                  "Data": 0.0
                },
                "IsNormalMap": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "WrapModeU": {
                  "ID": const Uuid().v4(),
                  "Data": "Repeat"
                },
                "WrapModeV": {
                  "ID": const Uuid().v4(),
                  "Data": "Repeat"
                },
                "PowerOfTwoAlignThreshold": {
                  "ID": const Uuid().v4(),
                  "Data": 0.05
                },
                "CrunchCompressed": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "MaxSize": {
                  "ID": const Uuid().v4(),
                  "Data": null
                },
                "MipMaps": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "MipMapFilter": {
                  "ID": const Uuid().v4(),
                  "Data": "Box"
                },
                "Readable": {
                  "ID": const Uuid().v4(),
                  "Data": false
                }
              }
            },
            {
              "Type": "FrooxEngine.ItemTextureThumbnailSource",
              "Data": {
                "ID": const Uuid().v4(),
                "persistent-ID": const Uuid().v4(),
                "UpdateOrder": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "Enabled": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "Texture": {
                  "ID": const Uuid().v4(),
                  "Data": texture2dUid
                },
                "Crop": {
                  "ID": const Uuid().v4(),
                  "Data": null
                }
              }
            },
            {
              "Type": "FrooxEngine.SnapPlane",
              "Data": {
                "ID": const Uuid().v4(),
                "persistent-ID": const Uuid().v4(),
                "UpdateOrder": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "Enabled": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "Normal": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.0,
                    0.0,
                    1.0
                  ]
                },
                "SnapParent": {
                  "ID": const Uuid().v4(),
                  "Data": null
                }
              }
            },
            {
              "Type": "FrooxEngine.ReferenceProxy",
              "Data": {
                "ID": const Uuid().v4(),
                "persistent-ID": const Uuid().v4(),
                "UpdateOrder": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "Enabled": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "Reference": {
                  "ID": const Uuid().v4(),
                  "Data": texture2dUid
                },
                "SpawnInstanceOnTrigger": {
                  "ID": const Uuid().v4(),
                  "Data": false
                }
              }
            },
            {
              "Type": "FrooxEngine.AssetProxy`1[[FrooxEngine.Texture2D, FrooxEngine, Version=2022.1.28.1335, Culture=neutral, PublicKeyToken=null]]",
              "Data": {
                "ID": const Uuid().v4(),
                "persistent-ID": const Uuid().v4(),
                "UpdateOrder": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "Enabled": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "AssetReference": {
                  "ID": const Uuid().v4(),
                  "Data": texture2dUid
                }
              }
            },
            {
              "Type": "FrooxEngine.UnlitMaterial",
              "Data": {
                "ID": materialId,
                "persistent-ID": const Uuid().v4(),
                "UpdateOrder": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "Enabled": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "HighPriorityIntegration": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "TintColor": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    1.0,
                    1.0,
                    1.0,
                    1.0
                  ]
                },
                "Texture": {
                  "ID": const Uuid().v4(),
                  "Data": texture2dUid
                },
                "TextureScale": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    1.0,
                    1.0
                  ]
                },
                "TextureOffset": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.0,
                    0.0
                  ]
                },
                "MaskTexture": {
                  "ID": const Uuid().v4(),
                  "Data": null
                },
                "MaskScale": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    1.0,
                    1.0
                  ]
                },
                "MaskOffset": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.0,
                    0.0
                  ]
                },
                "MaskMode": {
                  "ID": const Uuid().v4(),
                  "Data": "MultiplyAlpha"
                },
                "BlendMode": {
                  "ID": const Uuid().v4(),
                  "Data": "Alpha"
                },
                "AlphaCutoff": {
                  "ID": const Uuid().v4(),
                  "Data": 0.5
                },
                "UseVertexColors": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "Sidedness": {
                  "ID": const Uuid().v4(),
                  "Data": "Double"
                },
                "ZWrite": {
                  "ID": const Uuid().v4(),
                  "Data": "Auto"
                },
                "OffsetTexture": {
                  "ID": const Uuid().v4(),
                  "Data": null
                },
                "OffsetMagnitude": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.0,
                    0.0
                  ]
                },
                "OffsetTextureScale": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    1.0,
                    1.0
                  ]
                },
                "OffsetTextureOffset": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.0,
                    0.0
                  ]
                },
                "PolarUVmapping": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "PolarPower": {
                  "ID": const Uuid().v4(),
                  "Data": 1.0
                },
                "StereoTextureTransform": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "RightEyeTextureScale": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    1.0,
                    1.0
                  ]
                },
                "RightEyeTextureOffset": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.0,
                    0.0
                  ]
                },
                "DecodeAsNormalMap": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "UseBillboardGeometry": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "UsePerBillboardScale": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "UsePerBillboardRotation": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "UsePerBillboardUV": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "BillboardSize": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.005,
                    0.005
                  ]
                },
                "OffsetFactor": {
                  "ID": const Uuid().v4(),
                  "Data": 0.0
                },
                "OffsetUnits": {
                  "ID": const Uuid().v4(),
                  "Data": 0.0
                },
                "RenderQueue": {
                  "ID": const Uuid().v4(),
                  "Data": -1
                },
                "_unlit-ID": const Uuid().v4(),
                "_unlitBillboard-ID": const Uuid().v4()
              }
            },
            {
              "Type": "FrooxEngine.QuadMesh",
              "Data": {
                "ID": quadMeshUid,
                "persistent-ID": const Uuid().v4(),
                "UpdateOrder": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "Enabled": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "HighPriorityIntegration": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "OverrideBoundingBox": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "OverridenBoundingBox": {
                  "ID": const Uuid().v4(),
                  "Data": {
                    "Min": [
                      0.0,
                      0.0,
                      0.0
                    ],
                    "Max": [
                      0.0,
                      0.0,
                      0.0
                    ]
                  }
                },
                "Rotation": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.0,
                    0.0,
                    0.0,
                    1.0
                  ]
                },
                "Size": {
                  "ID": quadMeshSizeUid,
                  "Data": [
                    1,
                    height/width
                  ]
                },
                "UVScale": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    1.0,
                    1.0
                  ]
                },
                "ScaleUVWithSize": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "UVOffset": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.0,
                    0.0
                  ]
                },
                "DualSided": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "UseVertexColors": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "UpperLeftColor": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    1.0,
                    1.0,
                    1.0,
                    1.0
                  ]
                },
                "LowerLeftColor": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    1.0,
                    1.0,
                    1.0,
                    1.0
                  ]
                },
                "LowerRightColor": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    1.0,
                    1.0,
                    1.0,
                    1.0
                  ]
                },
                "UpperRightColor": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    1.0,
                    1.0,
                    1.0,
                    1.0
                  ]
                }
              }
            },
            {
              "Type": "FrooxEngine.MeshRenderer",
              "Data": {
                "ID": const Uuid().v4(),
                "persistent-ID": const Uuid().v4(),
                "UpdateOrder": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "Enabled": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "Mesh": {
                  "ID": const Uuid().v4(),
                  "Data": quadMeshUid
                },
                "Materials": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    {
                      "ID": const Uuid().v4(),
                      "Data": materialId
                    }
                  ]
                },
                "MaterialPropertyBlocks": {
                  "ID": const Uuid().v4(),
                  "Data": []
                },
                "ShadowCastMode": {
                  "ID": const Uuid().v4(),
                  "Data": "On"
                },
                "MotionVectorMode": {
                  "ID": const Uuid().v4(),
                  "Data": "Object"
                },
                "SortingOrder": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                }
              }
            },
            {
              "Type": "FrooxEngine.BoxCollider",
              "Data": {
                "ID": const Uuid().v4(),
                "persistent-ID": const Uuid().v4(),
                "UpdateOrder": {
                  "ID": const Uuid().v4(),
                  "Data": 1000000
                },
                "Enabled": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "Offset": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.0,
                    0.0,
                    0.0
                  ]
                },
                "Type": {
                  "ID": const Uuid().v4(),
                  "Data": "NoCollision"
                },
                "Mass": {
                  "ID": const Uuid().v4(),
                  "Data": 1.0
                },
                "CharacterCollider": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "IgnoreRaycasts": {
                  "ID": const Uuid().v4(),
                  "Data": false
                },
                "Size": {
                  "ID": boxColliderSizeUid,
                  "Data": [
                    0.7071067,
                    0.7071067,
                    0.0
                  ]
                }
              }
            },
            {
              "Type": "FrooxEngine.Float2ToFloat3SwizzleDriver",
              "Data": {
                "ID": const Uuid().v4(),
                "persistent-ID": const Uuid().v4(),
                "UpdateOrder": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "Enabled": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "Source": {
                  "ID": const Uuid().v4(),
                  "Data": quadMeshSizeUid
                },
                "Target": {
                  "ID": const Uuid().v4(),
                  "Data": boxColliderSizeUid
                },
                "X": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "Y": {
                  "ID": const Uuid().v4(),
                  "Data": 1
                },
                "Z": {
                  "ID": const Uuid().v4(),
                  "Data": -1
                }
              }
            }
          ]
        },
        "Name": {
          "ID": const Uuid().v4(),
          "Data": "alice"
        },
        "Tag": {
          "ID": const Uuid().v4(),
          "Data": null
        },
        "Active": {
          "ID": const Uuid().v4(),
          "Data": true
        },
        "Persistent-ID": const Uuid().v4(),
        "Position": {
          "ID": const Uuid().v4(),
          "Data": [
            0.8303015,
            1.815294,
            0.494639724
          ]
        },
        "Rotation": {
          "ID": const Uuid().v4(),
          "Data": [
            1.05315749E-07,
            0.0222634021,
            -1.08297385E-07,
            0.999752164
          ]
        },
        "Scale": {
          "ID": const Uuid().v4(),
          "Data": [
            0.9999994,
            0.999999464,
            0.99999994
          ]
        },
        "OrderOffset": {
          "ID": const Uuid().v4(),
          "Data": 0
        },
        "ParentReference": const Uuid().v4(),
        "Children": []
      },
      "TypeVersions": {
        "FrooxEngine.Grabbable": 2,
        "FrooxEngine.QuadMesh": 1,
        "FrooxEngine.BoxCollider": 1
      }
    };
  }
}