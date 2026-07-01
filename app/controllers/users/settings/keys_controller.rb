module Users
  module Settings
    class KeysController < ApplicationController
      before_action :set_key, only: %i[show edit update destroy]

      # GET /keys or /keys.json
      def index
        @keys = current_user.keys
      end

      # GET /keys/1 or /keys/1.json
      def show; end

      # GET /keys/new
      def new
        @key = Key.new
        @key.expires_at = 1.year.from_now
      end

      # GET /keys/1/edit
      def edit; end

      # POST /keys or /keys.json
      def create
        @key = current_user.keys.build(key_params.merge(user_id: current_user.id))
        if @key.save
          redirect_to [:users, :settings, @key], notice: 'Key was successfully created.'
        else
          render :new, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /keys/1 or /keys/1.json
      def update
        if @key.update(key_params)
          redirect_to [:users, :settings, @key], notice: 'Key was successfully updated.'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      # DELETE /keys/1 or /keys/1.json
      def destroy
        @key.destroy!

        respond_to do |format|
          format.turbo_stream do
            flash.now[:notice] = 'Key was successfully destroyed.'
            render turbo_stream: [
              turbo_stream.remove(@key),
              turbo_stream.replace('flash', partial: 'shared/flash')
            ]
          end
          format.html { redirect_to users_settings_keys_path, status: :see_other, notice: 'Key was successfully destroyed.' }
        end
      end

      private

      # Use callbacks to share common setup or constraints between actions.
      def set_key
        @key = Key.find(params.expect(:id))
      end

      # Only allow a list of trusted parameters through.
      def key_params
        params.expect(key: %i[key title expires_at usage_type])
      end
   end
  end
end
