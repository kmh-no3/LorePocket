import Foundation
import RealityKit

@MainActor
final class ShowcaseScene {

    private let root = Entity()
    private let caseEntity = Entity()
    private let pedestalEntity = Entity()
    private let cardEntity = Entity()
    private let lightEntity = Entity()

    /// 未反映のあいだは nil。ケースだけを見て return すると、ライトや台座だけの変更が落ちる。
    private var currentPresentation: ShowcasePresentation?

    func makeRoot() -> Entity {
        if root.children.isEmpty {
            installGeometry()
            apply(.initial)
        }
        return root
    }

    func setRotationY(_ y: Float) {
        root.transform.rotation = simd_quatf(angle: y, axis: [0, 1, 0])
    }

    /// ケース、ライト、台座を一つのプレゼンテーションとして反映する。
    func apply(_ presentation: ShowcasePresentation) {
        if root.children.isEmpty {
            installGeometry()
        }
        guard presentation != currentPresentation else { return }
        currentPresentation = presentation

        applyCase(presentation.caseStyle)
        applyLight(presentation.light)
        applyPedestal(presentation.pedestal)
    }

    private func installGeometry() {
        root.position = [0, 0, 0]

        let pedestalMesh = MeshResource.generateBox(size: [0.55, 0.08, 0.38], cornerRadius: 0.02)
        pedestalEntity.components.set(
            ModelComponent(mesh: pedestalMesh, materials: [pedestalMaterial(.graphite)])
        )
        pedestalEntity.position = [0, -0.18, 0]

        let caseMesh = MeshResource.generateBox(size: [0.60, 0.35, 0.43], cornerRadius: 0.03)
        caseEntity.components.set(
            ModelComponent(mesh: caseMesh, materials: [caseMaterial(.clear)])
        )
        caseEntity.position = [0, 0.0, 0]

        let cardMesh = MeshResource.generateBox(size: [0.40, 0.56, 0.01], cornerRadius: 0.02)
        let cardMat = SimpleMaterial(color: .white, isMetallic: false)
        cardEntity.components.set(ModelComponent(mesh: cardMesh, materials: [cardMat]))
        cardEntity.position = [0, -0.02, 0.12]

        lightEntity.components.set(pointLight(.standard))
        lightEntity.position = [0.4, 0.4, 0.6]

        root.addChild(pedestalEntity)
        root.addChild(caseEntity)
        root.addChild(cardEntity)
        root.addChild(lightEntity)
    }

    private func applyCase(_ style: CaseStyle) {
        guard var model = caseEntity.components[ModelComponent.self] as? ModelComponent else { return }
        model.materials = [caseMaterial(style)]
        caseEntity.components.set(model)
    }

    private func applyLight(_ preset: LightPreset) {
        var point = lightEntity.components[PointLightComponent.self] ?? PointLightComponent()
        point.intensity = preset.intensity
        point.attenuationRadius = preset.attenuationRadius
        lightEntity.components.set(point)
    }

    private func applyPedestal(_ style: PedestalStyle) {
        guard var model = pedestalEntity.components[ModelComponent.self] as? ModelComponent else { return }
        model.materials = [pedestalMaterial(style)]
        pedestalEntity.components.set(model)
    }

    private func caseMaterial(_ style: CaseStyle) -> SimpleMaterial {
        switch style {
        case .clear:
            var material = SimpleMaterial(color: .white.withAlphaComponent(0.15), isMetallic: false)
            material.roughness = .float(0.1)
            return material
        case .smoky:
            var material = SimpleMaterial(color: .black.withAlphaComponent(0.18), isMetallic: false)
            material.roughness = .float(0.4)
            return material
        case .gold:
            var material = SimpleMaterial(color: .yellow.withAlphaComponent(0.20), isMetallic: true)
            material.roughness = .float(0.2)
            return material
        }
    }

    private func pedestalMaterial(_ style: PedestalStyle) -> SimpleMaterial {
        switch style {
        case .graphite:
            return SimpleMaterial(color: .darkGray, isMetallic: false)
        case .walnut:
            return SimpleMaterial(color: .brown, isMetallic: false)
        case .stone:
            return SimpleMaterial(color: .lightGray, isMetallic: false)
        }
    }

    private func pointLight(_ preset: LightPreset) -> PointLightComponent {
        var point = PointLightComponent()
        point.intensity = preset.intensity
        point.attenuationRadius = preset.attenuationRadius
        return point
    }
}
