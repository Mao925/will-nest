# 開発用：ビルドも実行も同じ swift イメージで行う

FROM swift:5.9

WORKDIR /app

# 依存を先に解決してキャッシュを効かせる
COPY Package.swift ./
RUN swift package resolve

# 残りのソースコードをコピー
COPY . .

# リリースビルド
RUN swift build -c release --product Run

# ポート公開
EXPOSE 8080

# 環境変数（開発用）
ENV PORT=8080
ENV ENVIRONMENT=development

# Vapor アプリの起動コマンド
CMD [".build/release/Run", "serve", "--hostname", "0.0.0.0", "--port", "8080"]
