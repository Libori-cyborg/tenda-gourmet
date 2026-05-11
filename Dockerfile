FROM php:8.2-cli

# Instalar dependencias del sistema y extensiones PHP que Laravel necesita
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    curl \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copiar Composer desde su imagen oficial
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Directorio de trabajo
WORKDIR /var/www

# Copiar todo el proyecto
COPY . .

# Crear estructura de storage si falta algun subdirectorio
RUN mkdir -p storage/framework/cache \
    && mkdir -p storage/framework/sessions \
    && mkdir -p storage/framework/views \
    && mkdir -p storage/logs \
    && mkdir -p bootstrap/cache

# Instalar dependencias de Laravel (sin dev, optimizado)
# Usamos --no-scripts para evitar que falle si artisan no esta listo aun
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# Permisos para storage y cache
RUN chmod -R 775 storage bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

# Puerto que Render asignara dinamicamente
EXPOSE 8000

# Comando de arranque: limpiar caches viejas, cachear config, migrar DB, levantar servidor
# El "|| true" en migrate evita que el servicio caiga si la DB no esta disponible al primer arranque
CMD php artisan config:clear && \
    php artisan config:cache && \
    php artisan view:cache && \
    php artisan migrate --force --no-interaction || true && \
    php artisan serve --host=0.0.0.0 --port=$PORT
