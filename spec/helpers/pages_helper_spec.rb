# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PagesHelper, type: :helper do
  describe 'helper module' do
    it 'can be included' do
      expect { helper.extend(described_class) }.not_to raise_error
    end

    it 'is a module' do
      expect(described_class).to be_a(Module)
    end
  end
end