import Foundation

enum SamplePacks {
    static let samplePack: Pack = {
        let meta = PackMeta(
            packId: "sample-pack-001",
            title: "Sample Pack",
            version: "1.0.0",
            language: "ja",
            description: "LorePocketのサンプルデータです（公開用の架空データ）。",
            cardCount: 10,
            tags: ["sample", "quotes"],
            legal: .init(source: "public", redistribution: "allowed")
        )
        
        let cards: [Card] = [
            .init(id: "sample-pack-001-001", genre: ["哲学"], text: "Always carry a notebook.", person: "Sample Author", background: "思いつきを逃さないための小さな習慣。", topics: ["habit", "learning"]),
            .init(id: "sample-pack-001-002", genre: ["仕事術"], text: "Make it work, then make it better.", person: "Sample Engineer", background: "まず動かして学ぶ、次に改善する。", topics: ["iteration", "shipping"]),
            .init(id: "sample-pack-001-003", genre: ["思考"], text: "Name the thing you fear.", person: "Sample Thinker", background: "恐れを言語化すると、対処の入口が見える。", topics: ["clarity", "courage"]),
            .init(id: "sample-pack-001-004", genre: ["学習"], text: "Review beats reread.", person: "Sample Teacher", background: "想起と反復が記憶を作る。", topics: ["memory", "spaced-repetition"]),
            .init(id: "sample-pack-001-005", genre: ["創作"], text: "Drafts are allowed to be ugly.", person: "Sample Writer", background: "最初から完成形を狙わない。", topics: ["creation", "process"]),
            .init(id: "sample-pack-001-006", genre: ["健康"], text: "Small walks compound.", person: "Sample Coach", background: "短い散歩は長期で効いてくる。", topics: ["health", "consistency"]),
            .init(id: "sample-pack-001-007", genre: ["時間"], text: "Protect the first hour.", person: "Sample Planner", background: "朝の1時間は一日の質を決める。", topics: ["focus", "routine"]),
            .init(id: "sample-pack-001-008", genre: ["対人"], text: "Ask one more question.", person: "Sample Listener", background: "相手の世界を広げる最短ルート。", topics: ["communication", "empathy"]),
            .init(id: "sample-pack-001-009", genre: ["技術"], text: "Logs are future you’s memory.", person: "Sample SRE", background: "観測できないものは直せない。", topics: ["observability", "debugging"]),
            .init(id: "sample-pack-001-010", genre: ["習慣"], text: "Reduce friction before adding willpower.", person: "Sample Builder", background: "意志力より仕組みを先に。", topics: ["behavior", "systems"]),
        ]
        
        let variants: [Variant] = [
            .init(variantId: "common", name: "通常", rarity: "common", weight: 80),
            .init(variantId: "foil", name: "箔押し", rarity: "rare", weight: 18),
            .init(variantId: "legend", name: "レジェンド", rarity: "legendary", weight: 2),
        ]
        
        return Pack(meta: meta, cards: cards, variants: variants)
    }()
}


