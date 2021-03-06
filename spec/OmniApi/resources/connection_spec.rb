require 'spec_helper'

describe OmniApi::Resources::Connection do
  let(:instance) { OmniApi::Resources::Connection.new('http://123.com') }

  subject { instance }

  it { is_expected.to respond_to(:error_handler=) }
  it { is_expected.to respond_to(:request) }

  describe '#request' do
    let(:path) { 'http://123.com/test' }

    subject { instance.request(:get, 'http://123.com/test', {}) }

    context 'the underlying connection fails to resolve the request' do
      before { ActiveResource::HttpMock.respond_to { |mock| mock.get path, {}, nil, 400 } }

      context 'an error handler is not set' do
        before { instance.error_handler = nil }

        it 'does not swallow the resulting exception' do
          expect { subject }.to raise_error(ActiveResource::BadRequest)
        end
      end

      context 'an error handler is set' do
        let(:error_handler) { double('error_handler') }

        before { instance.error_handler = error_handler }

        it 'calls the handle method of the error handler' do
          expect(error_handler).to receive(:handle).with(ActiveResource::BadRequest, instance, [:get, 'http://123.com/test', {}])

          subject
        end

        context 'the error handler handles the error successfully' do
          let(:response) { ActiveResource::Response.new(body: 'testR') }
          before { allow(error_handler).to receive(:handle).and_return(response) }

          it { is_expected.to be response }
        end
      end

      context 'a user_authorization_error_handler is used' do
        let(:error_handler) { OmniApi::Resources::UserAuthorizationErrorHandler.new }

        before { instance.error_handler = error_handler }

        context 'refreshing the access token works but the request always fails with 401' do
          before do
            token_request_headers = {'Content-Type' => 'application/json', 'Authorization' => 'bearer random'}
            ActiveResource::HttpMock.respond_to do |mock|
              mock.get path, {}, nil, 401
              mock.post '/api/v1/oauth2/token.json', token_request_headers, nil, 200
            end
          end

          it 'raises the first exception encountered after refreshing the token without causing a stack overflow' do
            expect { subject }.to raise_error(ActiveResource::UnauthorizedAccess)
          end
        end
      end
    end

    context 'the underlying connection resolves the request' do
      before { ActiveResource::HttpMock.respond_to { |mock | mock.get path, {}, 'testR', 200 } }

      it { is_expected.to be_a(ActiveResource::Response) }
      its(:body) { is_expected.to eq 'testR' }
    end
  end
end