# frozen_string_literal: true

class WebauthnCredential < ApplicationRecord
  belongs_to :user

  validates :external_id, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :nickname, presence: true, uniqueness: { scope: :user_id }
  validates :sign_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }

  # 最後の使用日時を更新
  def touch_last_used!
    update!(last_used_at: Time.current)
  end

  # サインカウンターを更新
  def update_sign_count!(new_count)
    update!(sign_count: new_count)
  end

  # WebAuthn gem用のCredential構造に変換
  def to_webauthn_credential
    WebAuthn::Credential.new(
      id: external_id,
      public_key: public_key,
      sign_count: sign_count
    )
  end

  # クレデンシャルを無効化
  def deactivate!
    update!(active: false)
  end

  # ユーザー表示用の情報
  def display_info
    {
      id: id,
      nickname: nickname,
      last_used: last_used_at&.strftime("%Y年%m月%d日 %H:%M"),
      created: created_at.strftime("%Y年%m月%d日")
    }
  end

  # セキュリティレベルの判定
  def security_level
    return "high" if sign_count > 0 && last_used_at && last_used_at > 30.days.ago
    return "medium" if sign_count > 0
    "low"
  end

  # セキュリティレベルの色クラス
  def security_level_color
    case security_level
    when "high"
      "text-green-600 bg-green-100"
    when "medium"
      "text-yellow-600 bg-yellow-100"
    else
      "text-gray-600 bg-gray-100"
    end
  end

  # セキュリティレベルのラベル
  def security_level_label
    case security_level
    when "high"
      "高"
    when "medium"
      "中"
    else
      "低"
    end
  end
end
