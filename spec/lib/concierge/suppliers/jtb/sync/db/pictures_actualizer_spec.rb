require 'spec_helper'

RSpec.describe JTB::Sync::DB::PicturesActualizer do
  let(:picture_attributes) do
    {
      language: "EN",
      city_code: "CHU",
      hotel_code: "W01",
      sequence: "1",
      category: "101",
      room_code: nil,
      url: "GMTGEWEB01/CHUW01/64400131000000063.jpg",
      comments: nil
   }
  end

  subject { described_class.new(tmp_path)}

  describe '#actualize' do
    context 'when diff file is empty' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'pictures', 'empty_diff') }

      it 'does nothing' do
        create_picture(picture_attributes)

        result = subject.actualize
        expect(result.success?).to be true

        pictures = JTB::Repositories::PictureRepository.all
        expect(pictures.length).to eq(1)
      end
    end

    context 'when diff file contains create update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'pictures', 'create') }

      it 'creates new picture' do
        picture = JTB::Repositories::PictureRepository.by_primary_key('EN', 'CHU', 'W01', 1)
        expect(picture).to be_nil

        result = subject.actualize
        expect(result.success?).to be true

        pictures = JTB::Repositories::PictureRepository.all
        expect(pictures.length).to eq(1)

        picture = JTB::Repositories::PictureRepository.by_primary_key('EN', 'CHU', 'W01', 1)
        expect(picture).not_to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('PictureMaster')
        expect(state.file_name).to eq('PictureMaster_Diff_20161006100829.zip')
      end
    end

    context 'when diff file contains update update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'pictures', 'update') }

      it 'updates picture' do
        create_picture(picture_attributes)
        create_picture(picture_attributes.merge({ hotel_code: 'W02' }))

        result = subject.actualize
        expect(result.success?).to be true

        # Updates picture
        picture = JTB::Repositories::PictureRepository.by_primary_key('EN', 'CHU', 'W01', 1)
        expect(picture.url).to eq('GMTGEWEB01/CHUW01/X64400131000000063.jpg')

        # Does not update another picture
        picture = JTB::Repositories::PictureRepository.by_primary_key('EN', 'CHU', 'W02', 1)
        expect(picture.url).to eq('GMTGEWEB01/CHUW01/64400131000000063.jpg')

        state = JTB::Repositories::StateRepository.by_prefix('PictureMaster')
        expect(state.file_name).to eq('PictureMaster_Diff_20161006100830.zip')
      end
    end

    context 'when directory contains ALL file' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'pictures', 'with_all') }

      it 'imports the pictures from the file' do
        result = subject.actualize
        expect(result.success?).to be true

        pictures = JTB::Repositories::PictureRepository.all
        expect(pictures.length).to eq(7)

        state = JTB::Repositories::StateRepository.by_prefix('PictureMaster')
        expect(state.file_name).to eq('PictureMaster_ALL_20161010.zip')
      end

      it 'clear table before actualisation' do
        create_picture(picture_attributes.merge({ language: 'QQ', city_code: 'QQQ', hotel_code: 'QQQ', sequence: 1 }))

        result = subject.actualize
        expect(result.success?).to be true

        picture = JTB::Repositories::PictureRepository.by_primary_key('QQ', 'QQQ', 'QQQ', 1)
        expect(picture).to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('PictureMaster')
        expect(state.file_name).to eq('PictureMaster_ALL_20161010.zip')
      end
    end

    context 'when diff file contains delete update_category' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'pictures', 'delete') }

      it 'delete the picture' do
        create_picture(picture_attributes)

        result = subject.actualize
        expect(result.success?).to be true

        pictures = JTB::Repositories::PictureRepository.all
        expect(pictures.length).to eq(0)

        state = JTB::Repositories::StateRepository.by_prefix('PictureMaster')
        expect(state.file_name).to eq('PictureMaster_Diff_20161006100831.zip')
      end
    end

    context 'when there is some problem during some file actualization' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'pictures', 'transaction') }

      it 'imports only files before invalid' do
        result = subject.actualize
        expect(result.success?).to be false

        pictures = JTB::Repositories::PictureRepository.all
        expect(pictures.length).to eq(1)

        picture = JTB::Repositories::PictureRepository.by_primary_key('EN', 'CHU', 'W01', 1)
        expect(picture).not_to be_nil

        state = JTB::Repositories::StateRepository.by_prefix('PictureMaster')
        expect(state.file_name).to eq('PictureMaster_Diff_20161006100832.zip')
      end
    end

    context 'when directory contains ALL and Diff files' do
      let(:tmp_path) { Hanami.root.join('spec', 'fixtures', 'jtb', 'sync', 'pictures', 'all_and_diff') }

      it 'imports all data' do
        result = subject.actualize
        expect(result.success?).to be true

        pictures = JTB::Repositories::PictureRepository.all
        expect(pictures.length).to eq(7)

        picture = JTB::Repositories::PictureRepository.by_primary_key('EN', 'CHU', 'W01', 1)
        expect(picture.url).to eq('GMTGEWEB01/CHUW01/X64400131000000063.jpg')

        state = JTB::Repositories::StateRepository.by_prefix('PictureMaster')
        expect(state.file_name).to eq('PictureMaster_Diff_20161010100830.zip')
      end
    end

    def create_picture(attributes)
      JTB::Repositories::PictureRepository.create(
        JTB::Entities::Picture.new(attributes)
      )
    end
  end
end