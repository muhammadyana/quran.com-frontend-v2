class VersePresenter < BasePresenter
  def verse
    if params[:id].to_s.include?(':')
      Verse.find_by_verse_key(params[:id])
    else
      Verse.find_by_id_or_key(params[:id])
    end
  end

  def approved_tafsirs
    ResourceContent.tafsirs.approved
  end

  def tafsir_languages
    list = Language
             .eager_load(:translated_name)
             .where(id: approved_tafsirs.select(:language_id))

    eager_load_translated_name(list).reduce({}) do |hash, translation|
      hash[translation.id] = translation
      hash
    end
  end

  def render_verse_words?
    true
  end

  def tafsir_name
    tafsir&.resource_name || ResourceContent.find(tafirs_filter).name
  end

  def chapter
    verse.chapter
  end

  def params_for_verse_link
    {}
  end

  def share_url
    translations = valid_translations

    if translations.present?
      "https://www.quran.com/#{verse.verse_key.sub(':', '/')}?translations=#{translations.join(',')}"
    else
      "https://www.quran.com/#{verse.verse_key.sub(':', '/')}"
    end
  end

  def share_text
    verse.text_uthmani
  end

  def share_title
    "#{chapter.name_simple} - #{verse.verse_key} - Quran.com"
  end

  def render_translations?
    false
  end

  def font
    'v1'
  end

  def font_method
    'code'
  end

  def show_verse_actions?
    false
  end

  def tafsir_text
    if(t= tafsir)
      t.text.gsub(/[.]+/, '.<br/>').to_s.html_safe
      t.text.to_s.html_safe
    else
      "Sorry we don't have tafsir for this ayah"
    end
  end

  def meta_page_type
    'article'
  end

  def language_name
    tafsir&.language_name
  end

  protected

  def tafsir
    strong_memoize :tafsir do
      verse.tafsirs.where(resource_content_id: tafirs_filter).first
    end
  end

  def tafirs_filter
    # Default tafsir is المیسر
    return 16 if params[:tafsir_id].blank?

    ResourceContent
      .approved
      .tafsirs
      .where(id: params[:tafsir_id])
      .or(ResourceContent.where(slug: params[:tafsir_id]))
      .first&.id || 16
  end
end
