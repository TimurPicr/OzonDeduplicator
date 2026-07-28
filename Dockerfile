FROM python:3.10-slim

# Определяем архитектуру (понадобится для установки пакетов)
ARG TARGETARCH
RUN echo "Архитектура: ${TARGETARCH}"

# =================================================================
# Установка системных зависимостей
# =================================================================
RUN apt-get update && apt-get install -y \
    # Для сборки пакетов
    build-essential \
    gcc \
    g++ \
    # Для научных библиотек
    libopenblas-dev \
    libomp-dev \
    # Локали для русского языка
    locales \
    curl \
    # Для загрузки моделей
    wget \
    && sed -i '/ru_RU.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Русская локаль
ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_ALL=ru_RU.UTF-8
ENV PYTHONIOENCODING=utf-8

# =================================================================
# Настройка рабочей директории
# =================================================================
WORKDIR /app

# =================================================================
# Установка Python-зависимостей
# =================================================================
# Копируем файл с зависимостями
COPY requirements.mac.txt .

# Устанавливаем с учетом архитектуры
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    # Для Apple Silicon могут понадобиться прекомпилированные wheel
    pip install --no-cache-dir -r requirements.mac.txt

# =================================================================
# Предзагрузка NLTK данных
# =================================================================
RUN python -c "import nltk; nltk.download('stopwords', quiet=True); nltk.download('punkt', quiet=True)"

# =================================================================
# Копируем код приложения
# =================================================================
COPY src/ ./src/
COPY main.py .
COPY entrypoint.sh .

# Создаем необходимые директории
RUN mkdir -p /app/data /app/output /app/models /app/logs

# Права на запуск
RUN chmod +x entrypoint.sh

# =================================================================
# Настройки производительности для Mac
# =================================================================
# Отключаем CUDA (на Mac все равно нет)
ENV CUDA_VISIBLE_DEVICES=-1
# Используем все доступные ядра CPU
ENV OMP_NUM_THREADS=4
# Оптимизация PyTorch для CPU
ENV MKL_NUM_THREADS=4
ENV OPENBLAS_NUM_THREADS=4

EXPOSE 8000

ENTRYPOINT ["./entrypoint.sh"]