import Foundation
import RealityKit

@MainActor
final class ShowcaseScene {

    private let root = Entity()
    private let caseEntity = Entity()
    private let pedestalEntity = Entity()
    private let cardEntity = Entity()
    private let lightEntity = Entity()

    private var currentStyle: CaseStyle = .clear

    func makeRoot() -> Entity {
        if root.children.isEmpty {
            setup()
        }
        return root
    }

    func setRotationY(_ y: Float) {
        root.transform.rotation = simd_quatf(angle: y, axis: [0, 1, 0])
    }

    func apply(style: CaseStyle) {
        guard style != currentStyle else { return }
        currentStyle = style

        let caseMaterial: Material = {
            switch style {
            case .clear:
                var m = SimpleMaterial(color: .white.withAlphaComponent(0.15), isMetallic: false)
                m.roughness = .float(0.1)
                return m
            case .smoky:
                var m = SimpleMaterial(color: .black.withAlphaComponent(0.18), isMetallic: false)
                m.roughness = .float(0.4)
                return m
            case .gold:
                var m = SimpleMaterial(color: .yellow.withAlphaComponent(0.20), isMetallic: true)
                m.roughness = .float(0.2)
                return m
            }
        }()

        if var model = caseEntity.components[ModelComponent.self] as? ModelComponent {
            model.materials = [caseMaterial]
            caseEntity.components.set(model)
        }
    }

    private func setup() {
        root.position = [0, 0, 0]

        let pedestalMesh = MeshResource.generateBox(size: [0.55, 0.08, 0.38], cornerRadius: 0.02)
        let pedestalMat = SimpleMaterial(color: .darkGray, isMetallic: false)
        pedestalEntity.components.set(ModelComponent(mesh: pedestalMesh, materials: [pedestalMat]))
        pedestalEntity.position = [0, -0.18, 0]

        let caseMesh = MeshResource.generateBox(size: [0.60, 0.35, 0.43], cornerRadius: 0.03)
        let caseMat = SimpleMaterial(color: .white.withAlphaComponent(0.15), isMetallic: false)
        caseEntity.components.set(ModelComponent(mesh: caseMesh, materials: [caseMat]))
        caseEntity.position = [0, 0.0, 0]

        let cardMesh = MeshResource.generateBox(size: [0.40, 0.56, 0.01], cornerRadius: 0.02)
        let cardMat = SimpleMaterial(color: .white, isMetallic: false)
        cardEntity.components.set(ModelComponent(mesh: cardMesh, materials: [cardMat]))
        cardEntity.position = [0, -0.02, 0.12]

        var point = PointLightComponent()
        point.intensity = 2000
        point.attenuationRadius = 2.0
        lightEntity.components.set(point)
        lightEntity.position = [0.4, 0.4, 0.6]

        root.addChild(pedestalEntity)
        root.addChild(caseEntity)
        root.addChild(cardEntity)
        root.addChild(lightEntity)
    }
}
