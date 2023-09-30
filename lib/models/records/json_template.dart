import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class JsonTemplate {
  static const String thumbUrl = "resdb:///8ed80703e48c3d1556093927b67298f3d5e10315e9f782ec56fc49d6366f09b7.webp";
  final Map data;

  JsonTemplate({required this.data});

  factory JsonTemplate.image({required String imageUri, required String filename, required int width, required int height}) {
    final texture2dUid = const Uuid().v4();
    final quadMeshUid = const Uuid().v4();
    final quadMeshSizeUid = const Uuid().v4();
    final materialId = const Uuid().v4();
    final boxColliderSizeUid = const Uuid().v4();
    final ratio = height/width;
    final data = {
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
                    ratio > 1 ? ratio : 1,
                    ratio > 1 ? 1 : ratio
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
          "Data": filename
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
    return JsonTemplate(data: data);
  }

  factory JsonTemplate.rawFile({required String assetUri, required String filename}) {
    final var20 = const Uuid().v4();
    final var19 = const Uuid().v4();
    final var18 = const Uuid().v4();
    final var17 = const Uuid().v4();
    final var16 = const Uuid().v4();
    final var15 = const Uuid().v4();
    final var14 = const Uuid().v4();
    final var13 = const Uuid().v4();
    final var12 = const Uuid().v4();
    final var11 = const Uuid().v4();
    final var10 = const Uuid().v4();
    final var9 = const Uuid().v4();
    final var8 = const Uuid().v4();
    final var7 = const Uuid().v4();
    final var6 = const Uuid().v4();
    final var5 = const Uuid().v4();
    final var4 = const Uuid().v4();
    final var3 = const Uuid().v4();
    final var2 = const Uuid().v4();
    final var1 = const Uuid().v4();
    final var0 = const Uuid().v4();
    final data = {
      "Object": {
        "ID": const Uuid().v4(),
        "Components": {
          "ID": const Uuid().v4(),
          "Data": [
            {
              "Type": "FrooxEngine.ObjectRoot",
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
                }
              }
            },
            {
              "Type": "FrooxEngine.StaticBinary",
              "Data": {
                "ID": var0,
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
                  "Data": "@$assetUri"
                }
              }
            },
            {
              "Type": "FrooxEngine.BinaryExportable",
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
                "Binary": {
                  "ID": const Uuid().v4(),
                  "Data": var0
                }
              }
            },
            {
              "Type": "FrooxEngine.FileMetadata",
              "Data": {
                "ID": var1,
                "persistent-ID": const Uuid().v4(),
                "UpdateOrder": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "Enabled": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "Filename": {
                  "ID": const Uuid().v4(),
                  "Data": filename
                },
                "MIME": {
                  "ID": const Uuid().v4(),
                  "Data": null
                },
                "IsProcessing-ID": const Uuid().v4()
              }
            },
            {
              "Type": "FrooxEngine.FileVisual",
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
                "MetadataSource": {
                  "ID": const Uuid().v4(),
                  "Data": var1
                },
                "TypeLabel": {
                  "ID": const Uuid().v4(),
                  "Data": var2
                },
                "NameLabel": {
                  "ID": const Uuid().v4(),
                  "Data": var3
                },
                "FillMaterial": {
                  "ID": const Uuid().v4(),
                  "Data": var4
                },
                "OutlineMaterial": {
                  "ID": const Uuid().v4(),
                  "Data": var5
                },
                "TypeMaterial": {
                  "ID": const Uuid().v4(),
                  "Data": var6
                }
              }
            },
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
            }
          ]
        },
        "Name": {
          "ID": const Uuid().v4(),
          "Data": filename
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
            1.12835562,
            1.54872811,
            -2.16048574
          ]
        },
        "Rotation": {
          "ID": const Uuid().v4(),
          "Data": [
            0.0814014,
            0.69532,
            -0.07976244,
            0.7096068
          ]
        },
        "Scale": {
          "ID": const Uuid().v4(),
          "Data": [
            1.00000036,
            0.99999994,
            1.00000036
          ]
        },
        "OrderOffset": {
          "ID": const Uuid().v4(),
          "Data": 0
        },
        "ParentReference": const Uuid().v4(),
        "Children": [
          {
            "ID": const Uuid().v4(),
            "Components": {
              "ID": const Uuid().v4(),
              "Data": []
            },
            "Name": {
              "ID": const Uuid().v4(),
              "Data": "FileVisual"
            },
            "Tag": {
              "ID": const Uuid().v4(),
              "Data": ""
            },
            "Active": {
              "ID": const Uuid().v4(),
              "Data": true
            },
            "Persistent-ID": const Uuid().v4(),
            "Position": {
              "ID": const Uuid().v4(),
              "Data": [
                0.0,
                0.0,
                0.0
              ]
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
            "Scale": {
              "ID": const Uuid().v4(),
              "Data": [
                1.0,
                1.0,
                1.0
              ]
            },
            "OrderOffset": {
              "ID": const Uuid().v4(),
              "Data": 0
            },
            "ParentReference": const Uuid().v4(),
            "Children": [
              {
                "ID": const Uuid().v4(),
                "Components": {
                  "ID": const Uuid().v4(),
                  "Data": [
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
                          "Data": var7
                        },
                        "Materials": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            {
                              "ID": const Uuid().v4(),
                              "Data": var4
                            },
                            {
                              "ID": const Uuid().v4(),
                              "Data": var5
                            },
                            {
                              "ID": const Uuid().v4(),
                              "Data": var6
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
                          "Data": 0
                        },
                        "Enabled": {
                          "ID": const Uuid().v4(),
                          "Data": true
                        },
                        "Offset": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            0.180121541,
                            0.0,
                            0.0669048056
                          ]
                        },
                        "Type": {
                          "ID": const Uuid().v4(),
                          "Data": "Static"
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
                          "ID": const Uuid().v4(),
                          "Data": [
                            2.360243,
                            2.5,
                            0.1516055
                          ]
                        }
                      }
                    }
                  ]
                },
                "Name": {
                  "ID": const Uuid().v4(),
                  "Data": "File Mesh"
                },
                "Tag": {
                  "ID": const Uuid().v4(),
                  "Data": ""
                },
                "Active": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "Persistent-ID": const Uuid().v4(),
                "Position": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    5.96046448E-08,
                    0.0,
                    0.0
                  ]
                },
                "Rotation": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    -1.19209275E-07,
                    0.0,
                    0.0,
                    1.0
                  ]
                },
                "Scale": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.04071409,
                    0.0407139659,
                    0.0407141037
                  ]
                },
                "OrderOffset": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "ParentReference": const Uuid().v4(),
                "Children": []
              },
              {
                "ID": const Uuid().v4(),
                "Components": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    {
                      "Type": "FrooxEngine.TextRenderer",
                      "Data": {
                        "ID": var3,
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
                        "Font": {
                          "ID": const Uuid().v4(),
                          "Data": var8
                        },
                        "Text": {
                          "ID": const Uuid().v4(),
                          "Data": basenameWithoutExtension(filename)
                        },
                        "ParseRichText": {
                          "ID": const Uuid().v4(),
                          "Data": true
                        },
                        "NullText": {
                          "ID": const Uuid().v4(),
                          "Data": ""
                        },
                        "Size": {
                          "ID": const Uuid().v4(),
                          "Data": 1.0
                        },
                        "HorizontalAlign": {
                          "ID": const Uuid().v4(),
                          "Data": "Center"
                        },
                        "VerticalAlign": {
                          "ID": const Uuid().v4(),
                          "Data": "Top"
                        },
                        "AlignmentMode": {
                          "ID": const Uuid().v4(),
                          "Data": "Geometric"
                        },
                        "Color": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            1.0,
                            1.0,
                            1.0,
                            1.0
                          ]
                        },
                        "Materials": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            {
                              "ID": const Uuid().v4(),
                              "Data": var9
                            }
                          ]
                        },
                        "LineHeight": {
                          "ID": const Uuid().v4(),
                          "Data": 0.8
                        },
                        "Bounded": {
                          "ID": const Uuid().v4(),
                          "Data": true
                        },
                        "BoundsSize": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            0.5,
                            0.2
                          ]
                        },
                        "BoundsAlignment": {
                          "ID": const Uuid().v4(),
                          "Data": "MiddleCenter"
                        },
                        "MaskPattern": {
                          "ID": const Uuid().v4(),
                          "Data": ""
                        },
                        "HorizontalAutoSize": {
                          "ID": const Uuid().v4(),
                          "Data": true
                        },
                        "VerticalAutoSize": {
                          "ID": const Uuid().v4(),
                          "Data": true
                        },
                        "CaretPosition": {
                          "ID": const Uuid().v4(),
                          "Data": -1
                        },
                        "SelectionStart": {
                          "ID": const Uuid().v4(),
                          "Data": -1
                        },
                        "CaretColor": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            1.0,
                            1.0,
                            1.0,
                            1.0
                          ]
                        },
                        "SelectionColor": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            0.0,
                            0.5,
                            0.2,
                            0.5
                          ]
                        },
                        "_legacyFontMaterial-ID": const Uuid().v4(),
                        "_legacyAlign-ID": const Uuid().v4()
                      }
                    },
                    {
                      "Type": "FrooxEngine.BoxCollider",
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
                        "Offset": {
                          "ID": var10,
                          "Data": [
                            0.0,
                            0.0590983443,
                            0.0
                          ]
                        },
                        "Type": {
                          "ID": const Uuid().v4(),
                          "Data": "Static"
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
                          "ID": var11,
                          "Data": [
                            0.5113616,
                            0.09316488,
                            0.0
                          ]
                        }
                      }
                    },
                    {
                      "Type": "FrooxEngine.BoundingBoxDriver",
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
                        "BoundedSource": {
                          "ID": const Uuid().v4(),
                          "Data": var3
                        },
                        "Size": {
                          "ID": const Uuid().v4(),
                          "Data": var11
                        },
                        "Center": {
                          "ID": const Uuid().v4(),
                          "Data": var10
                        },
                        "Padding": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            0.0,
                            0.0,
                            0.0
                          ]
                        },
                        "Scale": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            1.0,
                            1.0,
                            1.0
                          ]
                        }
                      }
                    }
                  ]
                },
                "Name": {
                  "ID": const Uuid().v4(),
                  "Data": "NameLabel"
                },
                "Tag": {
                  "ID": const Uuid().v4(),
                  "Data": ""
                },
                "Active": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "Persistent-ID": const Uuid().v4(),
                "Position": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.0009058714,
                    -0.08701205,
                    0.00394916534
                  ]
                },
                "Rotation": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.0009555904,
                    0.999872863,
                    0.000245468284,
                    0.01591436
                  ]
                },
                "Scale": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.3075354,
                    0.307534128,
                    0.307536483
                  ]
                },
                "OrderOffset": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "ParentReference": const Uuid().v4(),
                "Children": []
              },
              {
                "ID": const Uuid().v4(),
                "Components": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    {
                      "Type": "FrooxEngine.TextRenderer",
                      "Data": {
                        "ID": var2,
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
                        "Font": {
                          "ID": const Uuid().v4(),
                          "Data": var8
                        },
                        "Text": {
                          "ID": const Uuid().v4(),
                          "Data": extension(filename).toUpperCase()
                        },
                        "ParseRichText": {
                          "ID": const Uuid().v4(),
                          "Data": true
                        },
                        "NullText": {
                          "ID": const Uuid().v4(),
                          "Data": ""
                        },
                        "Size": {
                          "ID": const Uuid().v4(),
                          "Data": 1.0
                        },
                        "HorizontalAlign": {
                          "ID": const Uuid().v4(),
                          "Data": "Center"
                        },
                        "VerticalAlign": {
                          "ID": const Uuid().v4(),
                          "Data": "Middle"
                        },
                        "AlignmentMode": {
                          "ID": const Uuid().v4(),
                          "Data": "Geometric"
                        },
                        "Color": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            1.0,
                            1.0,
                            1.0,
                            1.0
                          ]
                        },
                        "Materials": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            {
                              "ID": const Uuid().v4(),
                              "Data": var9
                            }
                          ]
                        },
                        "LineHeight": {
                          "ID": const Uuid().v4(),
                          "Data": 0.8
                        },
                        "Bounded": {
                          "ID": const Uuid().v4(),
                          "Data": true
                        },
                        "BoundsSize": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            0.24,
                            1.0
                          ]
                        },
                        "BoundsAlignment": {
                          "ID": const Uuid().v4(),
                          "Data": "MiddleCenter"
                        },
                        "MaskPattern": {
                          "ID": const Uuid().v4(),
                          "Data": ""
                        },
                        "HorizontalAutoSize": {
                          "ID": const Uuid().v4(),
                          "Data": true
                        },
                        "VerticalAutoSize": {
                          "ID": const Uuid().v4(),
                          "Data": true
                        },
                        "CaretPosition": {
                          "ID": const Uuid().v4(),
                          "Data": -1
                        },
                        "SelectionStart": {
                          "ID": const Uuid().v4(),
                          "Data": -1
                        },
                        "CaretColor": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            1.0,
                            1.0,
                            1.0,
                            1.0
                          ]
                        },
                        "SelectionColor": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            0.0,
                            0.5,
                            0.2,
                            0.5
                          ]
                        },
                        "_legacyFontMaterial-ID": const Uuid().v4(),
                        "_legacyAlign-ID": const Uuid().v4()
                      }
                    },
                    {
                      "Type": "FrooxEngine.BoxCollider",
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
                        "Offset": {
                          "ID": var12,
                          "Data": [
                            -3.7252903E-09,
                            0.0,
                            0.0
                          ]
                        },
                        "Type": {
                          "ID": const Uuid().v4(),
                          "Data": "Static"
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
                          "ID": var13,
                          "Data": [
                            0.1862,
                            0.08590001,
                            0.0
                          ]
                        }
                      }
                    },
                    {
                      "Type": "FrooxEngine.BoundingBoxDriver",
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
                        "BoundedSource": {
                          "ID": const Uuid().v4(),
                          "Data": var2
                        },
                        "Size": {
                          "ID": const Uuid().v4(),
                          "Data": var13
                        },
                        "Center": {
                          "ID": const Uuid().v4(),
                          "Data": var12
                        },
                        "Padding": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            0.0,
                            0.0,
                            0.0
                          ]
                        },
                        "Scale": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            1.0,
                            1.0,
                            1.0
                          ]
                        }
                      }
                    }
                  ]
                },
                "Name": {
                  "ID": const Uuid().v4(),
                  "Data": "TypeLabel"
                },
                "Tag": {
                  "ID": const Uuid().v4(),
                  "Data": ""
                },
                "Active": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "Persistent-ID": const Uuid().v4(),
                "Position": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.02074349,
                    0.02509594,
                    0.00547504425
                  ]
                },
                "Rotation": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    3.05048379E-05,
                    0.9999975,
                    -0.000117197917,
                    -0.0022352722
                  ]
                },
                "Scale": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.268987477,
                    0.2689861,
                    0.268988162
                  ]
                },
                "OrderOffset": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "ParentReference": const Uuid().v4(),
                "Children": []
              },
              {
                "ID": const Uuid().v4(),
                "Components": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    {
                      "Type": "FrooxEngine.Panner2D",
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
                        "_target": {
                          "ID": const Uuid().v4(),
                          "Data": var14
                        },
                        "_offset": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            0.0,
                            0.0
                          ]
                        },
                        "_preOffset": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            0.0,
                            0.0
                          ]
                        },
                        "_speed": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            1.0,
                            0.0
                          ]
                        },
                        "_repeat": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            1.0,
                            1.0
                          ]
                        },
                        "PingPong": {
                          "ID": const Uuid().v4(),
                          "Data": false
                        }
                      }
                    },
                    {
                      "Type": "FrooxEngine.PBS_DualSidedMetallic",
                      "Data": {
                        "ID": var5,
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
                        "TextureScale": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            1.0,
                            1.0
                          ]
                        },
                        "TextureOffset": {
                          "ID": var14,
                          "Data": [
                            0.399169922,
                            0.0
                          ]
                        },
                        "AlbedoColor": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            0.25,
                            0.25,
                            0.25,
                            1.0
                          ]
                        },
                        "AlbedoTexture": {
                          "ID": const Uuid().v4(),
                          "Data": null
                        },
                        "EmissiveColor": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            0.0,
                            0.0,
                            0.0,
                            1.0
                          ]
                        },
                        "EmissiveMap": {
                          "ID": const Uuid().v4(),
                          "Data": var15
                        },
                        "NormalMap": {
                          "ID": const Uuid().v4(),
                          "Data": null
                        },
                        "NormalScale": {
                          "ID": const Uuid().v4(),
                          "Data": 1.0
                        },
                        "OcclusionMap": {
                          "ID": const Uuid().v4(),
                          "Data": null
                        },
                        "Culling": {
                          "ID": const Uuid().v4(),
                          "Data": "Off"
                        },
                        "AlphaHandling": {
                          "ID": const Uuid().v4(),
                          "Data": "Opaque"
                        },
                        "AlphaClip": {
                          "ID": const Uuid().v4(),
                          "Data": 0.0
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
                        "Metallic": {
                          "ID": const Uuid().v4(),
                          "Data": 1.0
                        },
                        "Smoothness": {
                          "ID": const Uuid().v4(),
                          "Data": 0.9
                        },
                        "MetallicMap": {
                          "ID": const Uuid().v4(),
                          "Data": null
                        },
                        "_regular-ID": const Uuid().v4(),
                        "_transparent-ID": const Uuid().v4()
                      }
                    }
                  ]
                },
                "Name": {
                  "ID": const Uuid().v4(),
                  "Data": "OutlineMaterial"
                },
                "Tag": {
                  "ID": const Uuid().v4(),
                  "Data": ""
                },
                "Active": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "Persistent-ID": const Uuid().v4(),
                "Position": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.0,
                    0.0,
                    0.0
                  ]
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
                "Scale": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.000407140964,
                    0.000407139567,
                    0.000407140964
                  ]
                },
                "OrderOffset": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "ParentReference": const Uuid().v4(),
                "Children": []
              },
              {
                "ID": const Uuid().v4(),
                "Components": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    {
                      "Type": "FrooxEngine.PBS_DualSidedMetallic",
                      "Data": {
                        "ID": var4,
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
                        "AlbedoColor": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            1.0,
                            1.0,
                            1.0,
                            1.0
                          ]
                        },
                        "AlbedoTexture": {
                          "ID": const Uuid().v4(),
                          "Data": null
                        },
                        "EmissiveColor": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            0.0,
                            0.0,
                            0.0,
                            1.0
                          ]
                        },
                        "EmissiveMap": {
                          "ID": const Uuid().v4(),
                          "Data": null
                        },
                        "NormalMap": {
                          "ID": const Uuid().v4(),
                          "Data": null
                        },
                        "NormalScale": {
                          "ID": const Uuid().v4(),
                          "Data": 1.0
                        },
                        "OcclusionMap": {
                          "ID": const Uuid().v4(),
                          "Data": null
                        },
                        "Culling": {
                          "ID": const Uuid().v4(),
                          "Data": "Off"
                        },
                        "AlphaHandling": {
                          "ID": const Uuid().v4(),
                          "Data": "Opaque"
                        },
                        "AlphaClip": {
                          "ID": const Uuid().v4(),
                          "Data": 0.0
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
                        "Metallic": {
                          "ID": const Uuid().v4(),
                          "Data": 0.0
                        },
                        "Smoothness": {
                          "ID": const Uuid().v4(),
                          "Data": 0.75
                        },
                        "MetallicMap": {
                          "ID": const Uuid().v4(),
                          "Data": null
                        },
                        "_regular-ID": const Uuid().v4(),
                        "_transparent-ID": const Uuid().v4()
                      }
                    }
                  ]
                },
                "Name": {
                  "ID": const Uuid().v4(),
                  "Data": "FillMaterial"
                },
                "Tag": {
                  "ID": const Uuid().v4(),
                  "Data": ""
                },
                "Active": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "Persistent-ID": const Uuid().v4(),
                "Position": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.0,
                    0.0,
                    0.0
                  ]
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
                "Scale": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.000407140964,
                    0.000407139567,
                    0.000407140964
                  ]
                },
                "OrderOffset": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "ParentReference": const Uuid().v4(),
                "Children": []
              },
              {
                "ID": const Uuid().v4(),
                "Components": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    {
                      "Type": "FrooxEngine.PBS_DualSidedMetallic",
                      "Data": {
                        "ID": var6,
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
                        "AlbedoColor": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            0.25,
                            0.25,
                            0.25,
                            1.0
                          ]
                        },
                        "AlbedoTexture": {
                          "ID": const Uuid().v4(),
                          "Data": null
                        },
                        "EmissiveColor": {
                          "ID": const Uuid().v4(),
                          "Data": [
                            0.0,
                            0.0,
                            0.0,
                            1.0
                          ]
                        },
                        "EmissiveMap": {
                          "ID": const Uuid().v4(),
                          "Data": null
                        },
                        "NormalMap": {
                          "ID": const Uuid().v4(),
                          "Data": null
                        },
                        "NormalScale": {
                          "ID": const Uuid().v4(),
                          "Data": 1.0
                        },
                        "OcclusionMap": {
                          "ID": const Uuid().v4(),
                          "Data": null
                        },
                        "Culling": {
                          "ID": const Uuid().v4(),
                          "Data": "Off"
                        },
                        "AlphaHandling": {
                          "ID": const Uuid().v4(),
                          "Data": "Opaque"
                        },
                        "AlphaClip": {
                          "ID": const Uuid().v4(),
                          "Data": 0.0
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
                        "Metallic": {
                          "ID": const Uuid().v4(),
                          "Data": 0.0
                        },
                        "Smoothness": {
                          "ID": const Uuid().v4(),
                          "Data": 0.8
                        },
                        "MetallicMap": {
                          "ID": const Uuid().v4(),
                          "Data": null
                        },
                        "_regular-ID": const Uuid().v4(),
                        "_transparent-ID": const Uuid().v4()
                      }
                    }
                  ]
                },
                "Name": {
                  "ID": const Uuid().v4(),
                  "Data": "TypeMaterial"
                },
                "Tag": {
                  "ID": const Uuid().v4(),
                  "Data": ""
                },
                "Active": {
                  "ID": const Uuid().v4(),
                  "Data": true
                },
                "Persistent-ID": const Uuid().v4(),
                "Position": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.0,
                    0.0,
                    0.0
                  ]
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
                "Scale": {
                  "ID": const Uuid().v4(),
                  "Data": [
                    0.000407140964,
                    0.000407139567,
                    0.000407140964
                  ]
                },
                "OrderOffset": {
                  "ID": const Uuid().v4(),
                  "Data": 0
                },
                "ParentReference": const Uuid().v4(),
                "Children": []
              }
            ]
          }
        ]
      },
      "Assets": [
        {
          "Type": "FrooxEngine.StaticMesh",
          "Data": {
            "ID": var7,
            "persistent": {
              "ID": const Uuid().v4(),
              "Data": true
            },
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
              "Data": "@resdb:///3738bf6fc560f7d08d872ce12b06f4d9337ac5da415b6de6008a49ca128658ec"
            },
            "Readable": {
              "ID": const Uuid().v4(),
              "Data": false
            }
          }
        },
        {
          "Type": "FrooxEngine.FontChain",
          "Data": {
            "ID": var8,
            "persistent": {
              "ID": const Uuid().v4(),
              "Data": true
            },
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
            "MainFont": {
              "ID": const Uuid().v4(),
              "Data": var16
            },
            "FallbackFonts": {
              "ID": const Uuid().v4(),
              "Data": [
                {
                  "ID": const Uuid().v4(),
                  "Data": var17
                },
                {
                  "ID": const Uuid().v4(),
                  "Data": var18
                },
                {
                  "ID": const Uuid().v4(),
                  "Data": var19
                },
                {
                  "ID": const Uuid().v4(),
                  "Data": var20
                }
              ]
            }
          }
        },
        {
          "Type": "FrooxEngine.StaticFont",
          "Data": {
            "ID": var16,
            "persistent": {
              "ID": const Uuid().v4(),
              "Data": true
            },
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
              "Data": "@resdb:///c801b8d2522fb554678f17f4597158b1af3f9be3abd6ce35d5a3112a81e2bf39"
            },
            "Padding": {
              "ID": const Uuid().v4(),
              "Data": 1
            },
            "PixelRange": {
              "ID": const Uuid().v4(),
              "Data": 4
            },
            "GlyphEmSize": {
              "ID": const Uuid().v4(),
              "Data": 32
            }
          }
        },
        {
          "Type": "FrooxEngine.StaticFont",
          "Data": {
            "ID": var17,
            "persistent": {
              "ID": const Uuid().v4(),
              "Data": true
            },
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
              "Data": "@resdb:///4cac521169034ddd416c6deffe2eb16234863761837df677a910697ec5babd25"
            },
            "Padding": {
              "ID": const Uuid().v4(),
              "Data": 1
            },
            "PixelRange": {
              "ID": const Uuid().v4(),
              "Data": 4
            },
            "GlyphEmSize": {
              "ID": const Uuid().v4(),
              "Data": 32
            }
          }
        },
        {
          "Type": "FrooxEngine.StaticFont",
          "Data": {
            "ID": var18,
            "persistent": {
              "ID": const Uuid().v4(),
              "Data": true
            },
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
              "Data": "@resdb:///23e7ad7cb0a5a4cf75e07c9e0848b1eb06bba15e8fa9b8cb0579fc823c532927"
            },
            "Padding": {
              "ID": const Uuid().v4(),
              "Data": 1
            },
            "PixelRange": {
              "ID": const Uuid().v4(),
              "Data": 4
            },
            "GlyphEmSize": {
              "ID": const Uuid().v4(),
              "Data": 32
            }
          }
        },
        {
          "Type": "FrooxEngine.StaticFont",
          "Data": {
            "ID": var19,
            "persistent": {
              "ID": const Uuid().v4(),
              "Data": true
            },
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
              "Data": "@resdb:///415dc6290378574135b64c808dc640c1df7531973290c4970c51fdeb849cb0c5"
            },
            "Padding": {
              "ID": const Uuid().v4(),
              "Data": 1
            },
            "PixelRange": {
              "ID": const Uuid().v4(),
              "Data": 4
            },
            "GlyphEmSize": {
              "ID": const Uuid().v4(),
              "Data": 32
            }
          }
        },
        {
          "Type": "FrooxEngine.StaticFont",
          "Data": {
            "ID": var20,
            "persistent": {
              "ID": const Uuid().v4(),
              "Data": true
            },
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
              "Data": "@resdb:///bcda0bcc22bab28ea4fedae800bfbf9ec76d71cc3b9f851779a35b7e438a839d"
            },
            "Padding": {
              "ID": const Uuid().v4(),
              "Data": 1
            },
            "PixelRange": {
              "ID": const Uuid().v4(),
              "Data": 4
            },
            "GlyphEmSize": {
              "ID": const Uuid().v4(),
              "Data": 32
            }
          }
        },
        {
          "Type": "FrooxEngine.TextUnlitMaterial",
          "Data": {
            "ID": var9,
            "persistent": {
              "ID": const Uuid().v4(),
              "Data": true
            },
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
            "_shader-ID": const Uuid().v4(),
            "FontAtlas": {
              "ID": const Uuid().v4(),
              "Data": null
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
            "OutlineColor": {
              "ID": const Uuid().v4(),
              "Data": [
                0.0,
                0.0,
                0.0,
                1.0
              ]
            },
            "BackgroundColor": {
              "ID": const Uuid().v4(),
              "Data": [
                0.0,
                0.0,
                0.0,
                1.0
              ]
            },
            "AutoBackgroundColor": {
              "ID": const Uuid().v4(),
              "Data": true
            },
            "GlyphRenderMethod": {
              "ID": const Uuid().v4(),
              "Data": "MSDF"
            },
            "PixelRange": {
              "ID": const Uuid().v4(),
              "Data": 4.0
            },
            "FaceDilate": {
              "ID": const Uuid().v4(),
              "Data": 0.0
            },
            "OutlineThickness": {
              "ID": const Uuid().v4(),
              "Data": 0.0
            },
            "FaceSoftness": {
              "ID": const Uuid().v4(),
              "Data": 0.0
            },
            "BlendMode": {
              "ID": const Uuid().v4(),
              "Data": "Alpha"
            },
            "Sidedness": {
              "ID": const Uuid().v4(),
              "Data": "Double"
            },
            "ZWrite": {
              "ID": const Uuid().v4(),
              "Data": "Auto"
            },
            "ZTest": {
              "ID": const Uuid().v4(),
              "Data": "LessOrEqual"
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
            }
          }
        },
        {
          "Type": "FrooxEngine.StaticTexture2D",
          "Data": {
            "ID": var15,
            "persistent": {
              "ID": const Uuid().v4(),
              "Data": true
            },
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
              "Data": "@resdb:///274f0d4ea4bce93abc224c9ae9f9a97a9a396b382c5338f71c738d1591dd5c35.webp"
            },
            "FilterMode": {
              "ID": const Uuid().v4(),
              "Data": "Anisotropic"
            },
            "AnisotropicLevel": {
              "ID": const Uuid().v4(),
              "Data": 8
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
        }
      ],
      "TypeVersions": {
        "FrooxEngine.Grabbable": 2,
        "FrooxEngine.BoxCollider": 1,
        "FrooxEngine.TextRenderer": 5
      }
    };
    return JsonTemplate(data: data);
  }
}