import { Controller } from "@hotwired/stimulus"

// Fizzy soda bubble animation with realistic physics
export default class extends Controller {
  static values = {
    count: { type: Number, default: 80 },
    streams: { type: Number, default: 5 },
    continuous: { type: Boolean, default: true }
  }

  connect() {
    this.bubbles = []
    this.streamPositions = []
    this.createBubbleContainer()
    this.initializeStreams()
    this.spawnInitialBubbles()

    if (this.continuousValue) {
      this.startContinuousSpawning()
    }
  }

  disconnect() {
    if (this.spawnInterval) clearInterval(this.spawnInterval)
    if (this.streamInterval) clearInterval(this.streamInterval)
    if (this.container) this.container.remove()
  }

  createBubbleContainer() {
    this.container = document.createElement("div")
    this.container.className = "bubbles-container"
    this.element.appendChild(this.container)
  }

  initializeStreams() {
    // Create fixed nucleation points for bubble streams (like in a real glass)
    for (let i = 0; i < this.streamsValue; i++) {
      this.streamPositions.push({
        x: this.randomBetween(10, 90),
        baseSize: this.randomBetween(3, 6),
        speed: this.randomBetween(3, 5)
      })
    }

    // Spawn stream bubbles at regular intervals
    this.streamInterval = setInterval(() => {
      this.streamPositions.forEach(stream => {
        this.createStreamBubble(stream)
      })
    }, 300)
  }

  spawnInitialBubbles() {
    // Spawn random bubbles at different starting positions
    for (let i = 0; i < this.countValue; i++) {
      setTimeout(() => this.createBubble(), i * 80)
    }
  }

  startContinuousSpawning() {
    // Continuously spawn random bubbles
    this.spawnInterval = setInterval(() => {
      if (this.bubbles.length < this.countValue * 2) {
        this.createBubble()
        // Occasionally spawn a small cluster
        if (Math.random() < 0.2) {
          setTimeout(() => this.createBubble(), 50)
          setTimeout(() => this.createBubble(), 100)
        }
      }
    }, 150)
  }

  createStreamBubble(stream) {
    const bubble = document.createElement("div")
    bubble.className = "bubble bubble--stream"

    // Stream bubbles are more uniform - slight variation
    const size = stream.baseSize + this.randomBetween(-1, 1)
    const duration = stream.speed + this.randomBetween(-0.5, 0.5)
    // Very slight x variation to create the "stringy" look
    const xOffset = this.randomBetween(-2, 2)

    const opacity = 0.4 + (size / 8) * 0.3

    bubble.style.cssText = `
      width: ${size}px;
      height: ${size}px;
      left: calc(${stream.x}% + ${xOffset}px);
      opacity: ${opacity};
      --rise-duration: ${duration}s;
      --wobble-amount: 5px;
      --wobble-speed: 2s;
    `

    this.container.appendChild(bubble)
    this.bubbles.push(bubble)

    setTimeout(() => {
      bubble.remove()
      this.bubbles = this.bubbles.filter(b => b !== bubble)
    }, duration * 1000)
  }

  createBubble() {
    const bubble = document.createElement("div")
    bubble.className = "bubble"

    // Random properties for variety
    const size = this.randomBetween(4, 14)
    const startX = this.randomBetween(5, 95)
    const duration = this.randomBetween(4, 8)
    const delay = this.randomBetween(0, 1)
    const wobbleAmount = this.randomBetween(15, 40)
    const wobbleSpeed = this.randomBetween(2, 4)

    // Size affects opacity (smaller = more transparent)
    const opacity = 0.3 + (size / 14) * 0.4

    bubble.style.cssText = `
      width: ${size}px;
      height: ${size}px;
      left: ${startX}%;
      opacity: ${opacity};
      --rise-duration: ${duration}s;
      --wobble-amount: ${wobbleAmount}px;
      --wobble-speed: ${wobbleSpeed}s;
      animation-delay: ${delay}s;
    `

    this.container.appendChild(bubble)
    this.bubbles.push(bubble)

    setTimeout(() => {
      bubble.remove()
      this.bubbles = this.bubbles.filter(b => b !== bubble)
    }, (duration + delay) * 1000)
  }

  randomBetween(min, max) {
    return Math.random() * (max - min) + min
  }
}
