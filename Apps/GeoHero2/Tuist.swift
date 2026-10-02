import ProjectDescription

// Tuist のクラウド機能は使わないので fullHandle を持たない（tuist generate にログインが不要になる）。
let tuist = Tuist(project: .tuist())
